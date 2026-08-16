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
 * TODO non-ASCII safety: subarray(start, start+75).toString('utf8') can split
 * a multi-byte char mid-sequence. All current event data is ASCII; if seed
 * data ever introduces non-ASCII, back the split off to the previous UTF-8
 * char boundary before slicing.
 */
function foldIcsLine(line: string): string {
  const bytes = Buffer.from(line, "utf8");
  if (bytes.length <= 75) return line;
  const out: string[] = [];
  let start = 0;
  while (start < bytes.length) {
    const chunk = bytes
      .subarray(start, Math.min(start + 75, bytes.length))
      .toString("utf8");
    out.push(chunk);
    start += 75;
  }
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

  if (event.location && event.location.length > 0) {
    lines.push(foldIcsLine(`LOCATION:${escapeIcsText(event.location)}`));
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
