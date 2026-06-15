import Link from "next/link";
import { formatInTimeZone } from "date-fns-tz";

import { getPastEvents, getUpcomingEvents } from "@/lib/queries/events";
import {
  CHICAGO_TZ,
  chicagoMonthKey,
  chicagoMonthLabel,
  formatTimeRange,
} from "@/lib/events-format";
import type { EventRow } from "@/lib/types";

interface EventListViewProps {
  filter: "upcoming" | "past";
}

export default async function EventListView({ filter }: EventListViewProps) {
  const events: EventRow[] =
    filter === "past" ? await getPastEvents(10) : await getUpcomingEvents();

  return (
    <section className="container mx-auto px-4 py-8 md:py-10">
      {/* Filter pills row */}
      <div className="flex flex-wrap items-center gap-3">
        <Link
          href="/events"
          aria-current={filter === "upcoming" ? "page" : undefined}
          className={
            filter === "upcoming"
              ? "bg-mavs-navy text-white px-4 py-2 rounded font-bold uppercase tracking-wide text-sm"
              : "bg-white border border-mavs-navy/30 text-mavs-navy hover:bg-mavs-navy/5 px-4 py-2 rounded font-bold uppercase tracking-wide text-sm"
          }
        >
          Upcoming
        </Link>
        <Link
          href="/events?filter=past"
          aria-current={filter === "past" ? "page" : undefined}
          className={
            filter === "past"
              ? "bg-mavs-navy text-white px-4 py-2 rounded font-bold uppercase tracking-wide text-sm"
              : "bg-white border border-mavs-navy/30 text-mavs-navy hover:bg-mavs-navy/5 px-4 py-2 rounded font-bold uppercase tracking-wide text-sm"
          }
        >
          Past
        </Link>
      </div>

      {events.length === 0 ? (
        <EmptyState filter={filter} />
      ) : filter === "upcoming" ? (
        <UpcomingList events={events} />
      ) : (
        <PastList events={events} />
      )}
    </section>
  );
}

function MonthGroupedList({ events }: { events: EventRow[] }) {
  // Precompute per-row "show heading" flags so the JSX render is pure (no
  // closure mutation between iterations). Works for both ascending
  // (Upcoming) and descending (Past) ordering — boundaries are detected
  // by change in month-key relative to the previous row.
  const monthKeys = events.map((e) => chicagoMonthKey(e.starts_at));
  const showHeadings = monthKeys.map((key, i) => i === 0 || key !== monthKeys[i - 1]);
  return (
    <>
      {events.map((event, i) => (
        <div key={event.id}>
          {showHeadings[i] ? (
            <h2 className="text-xl font-bold uppercase tracking-wide text-mavs-navy mt-8 mb-4">
              {chicagoMonthLabel(event.starts_at)}
            </h2>
          ) : null}
          <EventRowCard event={event} />
        </div>
      ))}
    </>
  );
}

function UpcomingList({ events }: { events: EventRow[] }) {
  return (
    <div className="mt-2">
      <MonthGroupedList events={events} />
    </div>
  );
}

function PastList({ events }: { events: EventRow[] }) {
  return (
    <div className="mt-2">
      <MonthGroupedList events={events} />
      <p className="text-sm text-muted-foreground mt-6">
        Showing 10 most recent events.
      </p>
    </div>
  );
}

function EmptyState({ filter }: { filter: "upcoming" | "past" }) {
  if (filter === "past") {
    return (
      <div className="mt-8 border border-mavs-navy/20 rounded p-8 text-center max-w-2xl mx-auto">
        <p className="text-foreground">No past events recorded yet.</p>
      </div>
    );
  }
  return (
    <div className="mt-8 border border-mavs-navy/20 rounded p-8 text-center max-w-2xl mx-auto">
      <p className="text-foreground">
        No upcoming events. Check back as we plan the 2026-27 season.
      </p>
      <p className="text-sm text-muted-foreground mt-3">
        Want to host an event? Email{" "}
        <a
          href="mailto:boosters@mcneilmavericks.org"
          className="text-mavs-navy hover:underline"
        >
          boosters@mcneilmavericks.org
        </a>
      </p>
    </div>
  );
}

type EventRowVariant = "default" | "on-green";

const VARIANT_CLASSES: Record<
  EventRowVariant,
  {
    border: string;
    muted: string;
    day: string;
    title: string;
    location: string;
  }
> = {
  default: {
    border: "border-mavs-navy/10",
    muted: "text-muted-foreground",
    day: "text-mavs-navy",
    title: "text-mavs-navy",
    location: "",
  },
  "on-green": {
    border: "border-white/20",
    muted: "text-white/80",
    day: "text-white",
    title: "text-white",
    location: "text-white",
  },
};

export function EventRowCard({
  event,
  variant = "default",
}: {
  event: EventRow;
  variant?: EventRowVariant;
}) {
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
  const v = VARIANT_CLASSES[variant];

  return (
    <article className={`flex gap-6 py-6 border-b ${v.border}`}>
      {/* Date block */}
      <div className="w-28 shrink-0 text-center">
        <div
          className={`text-xs font-bold uppercase tracking-wide ${v.muted}`}
        >
          {weekday}
        </div>
        <div className={`text-4xl font-black leading-none my-1 ${v.day}`}>
          {day}
        </div>
        <div className={`text-xs uppercase ${v.muted}`}>{monthAbbr}</div>
      </div>

      {/* Body */}
      <div className="flex-1 min-w-0">
        <p className={`text-sm ${v.muted}`}>
          {formatTimeRange(event.starts_at, event.ends_at)}
        </p>
        <h3 className={`text-xl font-bold mt-1 ${v.title}`}>
          <Link href={`/events/${event.slug}`} className="hover:underline">
            {event.title}
          </Link>
        </h3>
        {event.location ? (
          <p className={`text-sm mt-1 ${v.location}`}>{event.location}</p>
        ) : null}
        {event.description ? (
          <p className={`text-sm mt-2 line-clamp-3 ${v.muted}`}>
            {event.description}
          </p>
        ) : null}
      </div>

      {/* Cover image (md+ only, skip cell entirely if no image) */}
      {event.cover_image_url ? (
        <Link
          href={`/events/${event.slug}`}
          className="hidden md:block w-[280px] aspect-video shrink-0"
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={event.cover_image_url}
            alt=""
            className="w-full h-full object-cover rounded"
          />
        </Link>
      ) : null}
    </article>
  );
}
