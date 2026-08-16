import "server-only";

import { formatInTimeZone } from "date-fns-tz";

import type { EventRow } from "@/lib/types";

export const CHICAGO_TZ = "America/Chicago";

/**
 * Where a calendar row's title should link.
 *
 * Rows from the `events` table go to their own detail page. Rows derived from
 * the `games` table carry an explicit `href` to the games schedule instead —
 * they have no detail page, so linking them by slug would 404. Every render site
 * (list view, month view, and the ICS feed's URL: line) must go through here so
 * a game can never be linked as if it were an event.
 */
export function eventHref(event: EventRow): string {
  return event.href ?? `/events/${event.slug}`;
}

/**
 * Returns the Chicago calendar day-of-month (1-31) for an ISO timestamp.
 */
export function chicagoDayOfMonth(iso: string): number {
  return Number(formatInTimeZone(new Date(iso), CHICAGO_TZ, "d"));
}

/**
 * Returns the Chicago "YYYY-MM" key for an ISO timestamp -- used to detect
 * month-grouping boundaries in the upcoming list view.
 */
export function chicagoMonthKey(iso: string): string {
  return formatInTimeZone(new Date(iso), CHICAGO_TZ, "yyyy-MM");
}

/**
 * Returns the Chicago "MMMM yyyy" label ("September 2026") for an ISO timestamp.
 */
export function chicagoMonthLabel(iso: string): string {
  return formatInTimeZone(new Date(iso), CHICAGO_TZ, "MMMM yyyy");
}

/**
 * Format a single-event time range in Chicago wall-clock time.
 *
 *   No ends_at:                    "May 26 @ 7:00 PM"
 *   Same Chicago calendar day:     "May 26 @ 7:00 PM – 8:30 PM"
 *   Different Chicago calendar days: "September 10 @ 5:00 PM – September 12 @ 12:00 PM"
 */
export function formatTimeRange(
  startsAt: string,
  endsAt: string | null,
): string {
  const start = new Date(startsAt);
  const startLabel = formatInTimeZone(start, CHICAGO_TZ, "MMMM d @ h:mm a");

  if (!endsAt) {
    return startLabel;
  }

  const end = new Date(endsAt);
  const startDayKey = formatInTimeZone(start, CHICAGO_TZ, "yyyy-MM-dd");
  const endDayKey = formatInTimeZone(end, CHICAGO_TZ, "yyyy-MM-dd");

  if (startDayKey === endDayKey) {
    const endLabel = formatInTimeZone(end, CHICAGO_TZ, "h:mm a");
    return `${startLabel} – ${endLabel}`;
  }

  const endLabel = formatInTimeZone(end, CHICAGO_TZ, "MMMM d @ h:mm a");
  return `${startLabel} – ${endLabel}`;
}
