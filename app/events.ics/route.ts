import { NextRequest, NextResponse } from "next/server";

import { eventHref } from "@/lib/events-format";
import { getEventsForIcsFeed } from "@/lib/queries/events";
import type { EventRow } from "@/lib/types";

export const dynamic = "force-dynamic";

const CRLF = "\r\n";

/**
 * Format an ISO timestamp as a UTC iCalendar DATE-TIME value.
 * Example: '2026-05-27T00:00:00.000Z' -> '20260527T000000Z'
 */
function formatIcsDateUtc(iso: string): string {
  return new Date(iso)
    .toISOString()
    .replace(/[-:]/g, "")
    .replace(/\.\d{3}Z$/, "Z");
}

/**
 * Escape a TEXT-type iCalendar field per RFC 5545 § 3.3.11.
 * Order matters: backslash MUST be first so the later escapes don't
 * double-escape the backslashes they introduce.
 */
function escapeIcsText(s: string): string {
  return s
    .replace(/\\/g, "\\\\")
    .replace(/,/g, "\\,")
    .replace(/;/g, "\\;")
    .replace(/\r\n/g, "\\n")
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\n");
}

/**
 * Fold a content line per RFC 5545 § 3.1. Lines over 75 OCTETS (bytes when
 * UTF-8 encoded, not characters) MUST be split: CRLF + single leading space
 * starts the continuation.
 *
 * Splits on CHARACTER boundaries while measuring in bytes. The old version
 * sliced the byte buffer every 75 bytes and could cut a multi-byte character in
 * half, emitting U+FFFD; its TODO said "all current event data is ASCII", which
 * was already untrue (`Phil’s Ice House` carries a U+2019 apostrophe) and is
 * emphatically untrue now that LOCATION carries "name, street address" and runs
 * two to three times longer (migration 134). A venue name with an accent or a
 * curly quote would have corrupted the feed for every subscriber.
 *
 * Note this measures the ESCAPED line, which is correct — escaping happens
 * before folding, so the backslashes are part of the octet count.
 */
function foldIcsLine(line: string): string {
  if (Buffer.byteLength(line, "utf8") <= 75) return line;
  const out: string[] = [];
  let current = "";
  let currentBytes = 0;
  // Iterating the string yields whole code points, so a surrogate pair (emoji)
  // is never split either.
  for (const char of line) {
    const charBytes = Buffer.byteLength(char, "utf8");
    if (currentBytes + charBytes > 75) {
      out.push(current);
      current = "";
      currentBytes = 0;
    }
    current += char;
    currentBytes += charBytes;
  }
  if (current.length > 0) out.push(current);
  return out.join(`${CRLF} `);
}

/**
 * Build one VEVENT block. Returns the block as a string with internal CRLFs.
 */
function buildVEvent(event: EventRow, origin: string): string {
  const dtStamp = formatIcsDateUtc(event.updated_at);
  const dtStart = formatIcsDateUtc(event.starts_at);
  const endIso =
    event.ends_at ??
    new Date(new Date(event.starts_at).getTime() + 3600_000).toISOString();
  const dtEnd = formatIcsDateUtc(endIso);

  const lines: string[] = [
    "BEGIN:VEVENT",
    `UID:${event.id}@mcneilmavericks.org`,
    `DTSTAMP:${dtStamp}`,
    `DTSTART:${dtStart}`,
    `DTEND:${dtEnd}`,
    foldIcsLine(`SUMMARY:${escapeIcsText(event.title)}`),
  ];

  if (event.description && event.description.length > 0) {
    lines.push(foldIcsLine(`DESCRIPTION:${escapeIcsText(event.description)}`));
  }

  // "Burger Stadium, 3200 Jones Road, Austin, TX" rather than "Burger Stadium".
  // A calendar app can offer directions from an address and cannot from a name,
  // which is most of the point of subscribing to an away-game schedule. Falls
  // back to the bare label when the row has no venue (migration 134).
  const location = event.venue?.address
    ? `${event.location ?? event.venue.name}, ${event.venue.address}`
    : event.location;
  if (location && location.length > 0) {
    lines.push(foldIcsLine(`LOCATION:${escapeIcsText(location)}`));
  }

  lines.push(foldIcsLine(`URL:${origin}${eventHref(event)}`));
  lines.push("END:VEVENT");

  return lines.join(CRLF);
}

function deriveOrigin(request: NextRequest): string {
  const envUrl = process.env.NEXT_PUBLIC_SITE_URL;
  if (envUrl && envUrl.length > 0) {
    return envUrl.replace(/\/+$/, "");
  }
  const forwardedProto = request.headers.get("x-forwarded-proto") ?? "https";
  const host =
    request.headers.get("x-forwarded-host") ??
    request.headers.get("host") ??
    "localhost:3000";
  return `${forwardedProto}://${host}`;
}

export async function GET(request: NextRequest) {
  const events = await getEventsForIcsFeed();
  const origin = deriveOrigin(request);

  const calendarLines: string[] = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//McNeil Maverick Football Booster Club//Events//EN",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "X-WR-CALNAME:McNeil Mavericks Events",
    "X-WR-TIMEZONE:America/Chicago",
  ];

  for (const event of events) {
    calendarLines.push(buildVEvent(event, origin));
  }

  calendarLines.push("END:VCALENDAR");

  // Trailing CRLF per RFC 5545 § 3.4 (each content line ends with CRLF,
  // including the last one).
  const body = calendarLines.join(CRLF) + CRLF;

  return new NextResponse(body, {
    status: 200,
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Content-Disposition": 'inline; filename="mcneil-mavericks-events.ics"',
      "Cache-Control": "public, max-age=3600, s-maxage=3600",
    },
  });
}
