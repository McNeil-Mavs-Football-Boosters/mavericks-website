import Link from "next/link";
import { formatInTimeZone, fromZonedTime, toZonedTime } from "date-fns-tz";

import { getEventsInRange } from "@/lib/queries/events";
import {
  CHICAGO_TZ,
  chicagoDayOfMonth,
  eventHref,
  formatTimeRange,
} from "@/lib/events-format";
import type { EventRow } from "@/lib/types";

interface EventMonthViewProps {
  // Display month is 1-indexed (Jan=1..Dec=12). For Date constructor math we
  // subtract 1 internally.
  year: number;
  month: number;
  isCurrentMonth: boolean;
}

const WEEKDAY_LABELS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

function pad2(n: number): string {
  return n.toString().padStart(2, "0");
}

function shiftMonth(
  year: number,
  month: number,
  delta: number,
): { year: number; month: number } {
  // month here is 1-indexed; normalize via 0-indexed arithmetic.
  const zeroIdx = month - 1 + delta;
  const newYear = year + Math.floor(zeroIdx / 12);
  const newMonth = ((zeroIdx % 12) + 12) % 12;
  return { year: newYear, month: newMonth + 1 };
}

export default async function EventMonthView({
  year,
  month,
  isCurrentMonth,
}: EventMonthViewProps) {
  // Range bounds: convert "midnight on the 1st of the (next) month in Chicago"
  // to a UTC Date via fromZonedTime so the Supabase gte/lt comparison against
  // UTC timestamptz is correct across the DST boundary.
  const monthStartChicagoLocal = new Date(year, month - 1, 1, 0, 0, 0, 0);
  const nextMonthDate = shiftMonth(year, month, 1);
  const nextMonthStartChicagoLocal = new Date(
    nextMonthDate.year,
    nextMonthDate.month - 1,
    1,
    0,
    0,
    0,
    0,
  );
  const rangeStartUtc = fromZonedTime(monthStartChicagoLocal, CHICAGO_TZ);
  const rangeEndUtc = fromZonedTime(nextMonthStartChicagoLocal, CHICAGO_TZ);

  const events = await getEventsInRange(rangeStartUtc, rangeEndUtc, {
    includeGames: true,
  });

  // Bucket events by Chicago day-of-month.
  const dayBuckets = new Map<number, EventRow[]>();
  for (const ev of events) {
    const day = chicagoDayOfMonth(ev.starts_at);
    const bucket = dayBuckets.get(day);
    if (bucket) {
      bucket.push(ev);
    } else {
      dayBuckets.set(day, [ev]);
    }
  }

  // Compute today's Chicago year/month/day for the today-highlight comparison.
  const nowChicago = toZonedTime(new Date(), CHICAGO_TZ);
  const todayYear = nowChicago.getFullYear();
  const todayMonth = nowChicago.getMonth() + 1; // 1-indexed
  const todayDay = nowChicago.getDate();

  // Build the grid days. Start: Sunday on/before the 1st. End: Saturday
  // on/after the last day of the month. Compute the day-of-week of the 1st
  // using a Chicago-frame Date so we don't depend on the server's local zone.
  const firstOfMonthChicago = toZonedTime(rangeStartUtc, CHICAGO_TZ);
  const firstOfMonthDow = firstOfMonthChicago.getDay(); // 0=Sun..6=Sat
  const daysInMonth = new Date(year, month, 0).getDate(); // last day-of-month
  const lastOfMonthDow = (firstOfMonthDow + daysInMonth - 1) % 7;
  const leadingBlanks = firstOfMonthDow;
  const trailingBlanks = 6 - lastOfMonthDow;

  // Build the flat ordered list of grid cells. Each cell has an "in-month"
  // day (1..daysInMonth) or null (out-of-month padding).
  type Cell = { kind: "in" | "out"; day: number; sourceMonthLabel?: string };
  const cells: Cell[] = [];

  // Leading out-of-month days come from the previous month.
  const prevMonth = shiftMonth(year, month, -1);
  const prevMonthDays = new Date(prevMonth.year, prevMonth.month, 0).getDate();
  for (let i = leadingBlanks; i > 0; i--) {
    cells.push({ kind: "out", day: prevMonthDays - i + 1 });
  }
  for (let d = 1; d <= daysInMonth; d++) {
    cells.push({ kind: "in", day: d });
  }
  for (let d = 1; d <= trailingBlanks; d++) {
    cells.push({ kind: "out", day: d });
  }

  // Header navigation URLs.
  const prevNav = shiftMonth(year, month, -1);
  const nextNav = shiftMonth(year, month, 1);
  const prevUrl = `/events?view=month&date=${prevNav.year}-${pad2(prevNav.month)}`;
  const nextUrl = `/events?view=month&date=${nextNav.year}-${pad2(nextNav.month)}`;
  const headerLabel = formatInTimeZone(
    rangeStartUtc,
    CHICAGO_TZ,
    "MMMM yyyy",
  );

  return (
    <section className="container mx-auto px-4 py-8 md:py-10">
      {/* Header row */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div className="flex items-center gap-3">
          <Link
            href={prevUrl}
            aria-label="Previous month"
            className="inline-flex items-center justify-center w-10 h-10 border border-mavs-navy/30 rounded hover:bg-mavs-navy/5 text-mavs-navy"
          >
            ◀
          </Link>
          <h2 className="text-2xl md:text-3xl font-black uppercase tracking-tight text-mavs-navy">
            {headerLabel}
          </h2>
          <Link
            href={nextUrl}
            aria-label="Next month"
            className="inline-flex items-center justify-center w-10 h-10 border border-mavs-navy/30 rounded hover:bg-mavs-navy/5 text-mavs-navy"
          >
            ▶
          </Link>
        </div>
        {!isCurrentMonth ? (
          <Link
            href="/events?view=month"
            className="border border-mavs-navy text-mavs-navy px-4 py-2 rounded hover:bg-mavs-navy/5 font-bold uppercase tracking-wide text-sm self-start sm:self-auto"
          >
            Today
          </Link>
        ) : null}
      </div>

      {/* Desktop 7-col grid */}
      <div className="hidden md:grid grid-cols-7 mt-6 border-l border-t border-mavs-navy/10">
        {WEEKDAY_LABELS.map((label) => (
          <div
            key={label}
            className="border-r border-b border-mavs-navy/10 px-2 py-2 text-xs font-bold uppercase tracking-wide text-muted-foreground"
          >
            {label}
          </div>
        ))}
        {cells.map((cell, idx) => {
          const isToday =
            cell.kind === "in" &&
            year === todayYear &&
            month === todayMonth &&
            cell.day === todayDay;
          const dayEvents =
            cell.kind === "in" ? (dayBuckets.get(cell.day) ?? []) : [];
          return (
            <div
              key={idx}
              className="border-r border-b border-mavs-navy/10 min-h-32 p-2 relative"
            >
              {cell.kind === "out" ? (
                <span className="text-sm text-muted-foreground/50">
                  {cell.day}
                </span>
              ) : isToday ? (
                <span className="text-sm text-white bg-mavs-navy rounded-full w-6 h-6 inline-flex items-center justify-center">
                  {cell.day}
                </span>
              ) : (
                <span className="text-sm text-foreground">{cell.day}</span>
              )}
              {dayEvents.slice(0, 2).map((ev) => (
                <Link
                  key={ev.id}
                  href={eventHref(ev)}
                  className="block bg-mavs-navy text-white text-xs px-2 py-1 rounded truncate mt-1"
                  title={ev.title}
                >
                  {ev.title}
                </Link>
              ))}
              {dayEvents.length > 2 ? (
                <Link
                  href="/events"
                  className="text-xs text-mavs-navy hover:underline mt-1 block"
                >
                  +{dayEvents.length - 2} more
                </Link>
              ) : null}
            </div>
          );
        })}
      </div>

      {/* Mobile stacked weeks */}
      <MobileWeekList
        cells={cells}
        dayBuckets={dayBuckets}
        year={year}
        month={month}
      />
    </section>
  );
}

function MobileWeekList({
  cells,
  dayBuckets,
  year,
  month,
}: {
  cells: { kind: "in" | "out"; day: number }[];
  dayBuckets: Map<number, EventRow[]>;
  year: number;
  month: number;
}) {
  // Walk cells 7 at a time. Each chunk is one Sunday-first week.
  const weeks: { start: Date; end: Date; events: EventRow[] }[] = [];
  for (let i = 0; i < cells.length; i += 7) {
    const chunk = cells.slice(i, i + 7);
    // Resolve each cell to a real Chicago calendar date so we can label the
    // week range. Out-of-month cells reference the prev/next month.
    const resolveDate = (
      cell: { kind: "in" | "out"; day: number },
      indexInWeek: number,
    ): Date => {
      if (cell.kind === "in") {
        return new Date(year, month - 1, cell.day, 12, 0, 0); // noon to dodge DST
      }
      // Out-of-month: if early in the week, it's from previous month; if late,
      // it's from next month. Determined by position relative to in-month cells.
      const firstInIdx = chunk.findIndex((c) => c.kind === "in");
      if (firstInIdx === -1 || indexInWeek < firstInIdx) {
        // previous month
        const prev = shiftMonth(year, month, -1);
        return new Date(prev.year, prev.month - 1, cell.day, 12, 0, 0);
      }
      // next month
      const next = shiftMonth(year, month, 1);
      return new Date(next.year, next.month - 1, cell.day, 12, 0, 0);
    };

    const firstCell = chunk[0];
    const lastCell = chunk[chunk.length - 1];
    if (!firstCell || !lastCell) continue;
    const start = resolveDate(firstCell, 0);
    const end = resolveDate(lastCell, chunk.length - 1);

    // Collect events for in-month cells in this week.
    const weekEvents: EventRow[] = [];
    for (const cell of chunk) {
      if (cell.kind === "in") {
        const evs = dayBuckets.get(cell.day);
        if (evs) weekEvents.push(...evs);
      }
    }
    weeks.push({ start, end, events: weekEvents });
  }

  const totalEvents = Array.from(dayBuckets.values()).reduce(
    (sum, arr) => sum + arr.length,
    0,
  );

  if (totalEvents === 0) {
    return (
      <div className="md:hidden mt-6">
        <p className="text-muted-foreground text-center py-8">
          No events in this month.
        </p>
      </div>
    );
  }

  return (
    <div className="md:hidden mt-6 space-y-6">
      {weeks
        .filter((w) => w.events.length > 0)
        .map((w, idx) => {
          const startLabel = formatInTimeZone(w.start, CHICAGO_TZ, "MMMM d");
          const endLabel = formatInTimeZone(w.end, CHICAGO_TZ, "MMMM d");
          return (
            <section key={idx}>
              <h3 className="text-sm font-bold uppercase tracking-wide text-muted-foreground border-b border-mavs-navy/10 pb-1 mb-2">
                {startLabel} – {endLabel}
              </h3>
              <div>
                {w.events.map((ev) => (
                  <MobileWeekRow key={ev.id} event={ev} />
                ))}
              </div>
            </section>
          );
        })}
    </div>
  );
}

function MobileWeekRow({ event }: { event: EventRow }) {
  const weekday = formatInTimeZone(
    new Date(event.starts_at),
    CHICAGO_TZ,
    "EEE",
  ).toUpperCase();
  const day = formatInTimeZone(new Date(event.starts_at), CHICAGO_TZ, "d");
  const monthAbbr = formatInTimeZone(
    new Date(event.starts_at),
    CHICAGO_TZ,
    "MMM",
  ).toUpperCase();
  return (
    <article className="flex gap-4 py-4 border-b border-mavs-navy/10">
      <div className="w-20 shrink-0 text-center">
        <div className="text-xs font-bold uppercase tracking-wide text-muted-foreground">
          {weekday}
        </div>
        <div className="text-3xl font-black text-mavs-navy leading-none my-1">
          {day}
        </div>
        <div className="text-xs uppercase text-muted-foreground">
          {monthAbbr}
        </div>
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-xs text-muted-foreground">
          {formatTimeRange(event.starts_at, event.ends_at)}
        </p>
        <h4 className="text-base font-bold text-mavs-navy mt-1">
          <Link href={eventHref(event)} className="hover:underline">
            {event.title}
          </Link>
        </h4>
        {event.location ? (
          <p className="text-xs mt-1">
            {event.venue?.maps_url ? (
              <a
                href={event.venue.maps_url}
                target="_blank"
                rel="noopener noreferrer"
                className="hover:underline"
              >
                {event.location}
              </a>
            ) : (
              event.location
            )}
          </p>
        ) : null}
        {event.description ? (
          <p className="text-xs text-muted-foreground mt-1 line-clamp-2">
            {event.description}
          </p>
        ) : null}
      </div>
    </article>
  );
}
