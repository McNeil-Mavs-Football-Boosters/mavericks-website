import "server-only";

import { formatInTimeZone } from "date-fns-tz";

export const CHICAGO_TZ = "America/Chicago";

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
