import { formatInTimeZone } from "date-fns-tz";

import { CHICAGO_TZ } from "@/lib/events-format";

/**
 * Finding the current Mav Mail issue.
 *
 * Mav Mail is RRISD's weekly school newsletter — **not ours** — and it is where
 * football ticket links get published first. Jeremy, 2026-08-25: "how the hell
 * do you find it each week or whatever, it's like a random number or something."
 *
 * It is not random. The issue URL is a **date slug**, verified across three
 * consecutive weeks on 2026-08-25:
 *
 *   .../newsletters/mcneil-high-school/newsletters/mavmail-sunday-august-23-2026  -> 200
 *   .../mavmail-sunday-august-16-2026                                            -> 200
 *   .../mavmail-sunday-august-9-2026                                             -> 200
 *   .../mavmail-sunday-august-30-2026                                            -> 404 (unpublished)
 *   .../mavmail-sunday-august-02-2026                                            -> 404
 *
 * ⚠️ THE DAY IS NOT ZERO-PADDED. `august-9` resolves, `august-02` does not. That
 * is the single easiest way to break this.
 *
 * Published weekly on **Sundays**.
 *
 * ── WHY A PROBE AND NOT A FEED ──
 * There is no feed to consume. `/rss` and `/feed` under the newsletter host both
 * 404, the issue page carries no `<link rel="alternate">`, and the newsletter
 * INDEX itself 404s — so there is not even a stable "latest issue" page to link.
 * A constructed-and-verified URL is the only handle available.
 *
 * ── WHY IT MUST BE VERIFIED, NEVER ASSUMED ──
 * This depends on a third party's URL scheme. We only ever publish a URL that
 * answered 200 on this request. A constructed link that was never checked would
 * put a dead link on the site the moment RRISD renames a slug or skips a week —
 * and a dead "This Week's Mav Mail" is worse than no link, because the Subscribe
 * entry next to it already works.
 *
 * Known limitation, accepted: a special edition or an issue published on any day
 * other than Sunday is missed. This is a convenience on top of the subscribe
 * link, not a system of record.
 */

const BASE =
  "https://roundrockisd.edurooms.com/newsletters/mcneil-high-school/newsletters";

/** How many Sundays back to try before giving up. */
const LOOKBACK_SUNDAYS = 3;

/** One hour. The newsletter lands weekly; this is nowhere near tight enough to matter. */
const REVALIDATE_SECONDS = 3600;

export interface MavMailIssue {
  url: string;
  /** e.g. "August 23, 2026" — shown to the reader so they know which issue. */
  issueLabel: string;
}

/**
 * The slug for a given date. Exported for testing the padding rule without a
 * network call.
 */
export function mavMailSlug(date: Date): string {
  // Formatted in Chicago so a late-evening request does not roll to tomorrow.
  const month = formatInTimeZone(date, CHICAGO_TZ, "MMMM").toLowerCase();
  // "d" is deliberately unpadded — see the warning above. "dd" would 404.
  const day = formatInTimeZone(date, CHICAGO_TZ, "d");
  const year = formatInTimeZone(date, CHICAGO_TZ, "yyyy");
  return `mavmail-sunday-${month}-${day}-${year}`;
}

/** Most recent Sunday at or before `from`, in Chicago terms. */
function mostRecentSunday(from: Date): Date {
  // date-fns-tz's "i" gives ISO day of week, 1=Monday..7=Sunday.
  const isoDay = Number(formatInTimeZone(from, CHICAGO_TZ, "i"));
  const daysBack = isoDay % 7; // Sunday (7) -> 0, Monday (1) -> 1, Saturday (6) -> 6
  const d = new Date(from);
  d.setUTCDate(d.getUTCDate() - daysBack);
  return d;
}

/**
 * The newest published issue, or null.
 *
 * Returns null on any failure — 404s, a network error, a changed URL scheme.
 * Callers must render nothing in that case and leave the Subscribe link to carry
 * it.
 */
export async function getCurrentMavMail(): Promise<MavMailIssue | null> {
  let candidate = mostRecentSunday(new Date());

  for (let i = 0; i < LOOKBACK_SUNDAYS; i++) {
    const url = `${BASE}/${mavMailSlug(candidate)}`;
    try {
      const res = await fetch(url, {
        method: "HEAD",
        next: { revalidate: REVALIDATE_SECONDS },
      });
      if (res.ok) {
        return {
          url,
          issueLabel: formatInTimeZone(candidate, CHICAGO_TZ, "MMMM d, yyyy"),
        };
      }
    } catch {
      // Network failure is indistinguishable from "not published" for our
      // purposes, and both mean the same thing: do not publish a link.
    }
    candidate = new Date(candidate);
    candidate.setUTCDate(candidate.getUTCDate() - 7);
  }

  return null;
}
