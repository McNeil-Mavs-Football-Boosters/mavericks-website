import Link from "next/link";
import { toZonedTime } from "date-fns-tz";

import EventListView from "@/components/events/EventListView";
import EventMonthView from "@/components/events/EventMonthView";
import SubscribeButtonShape from "@/components/events/SubscribeButtonShape";
import { CHICAGO_TZ } from "@/lib/events-format";

export const dynamic = "force-dynamic";

export const metadata = {
  title: "Events | McNeil Mavericks Football",
  description:
    "Booster club events, parent meetings, and team gatherings for McNeil Mavericks Football.",
};

interface EventsPageProps {
  searchParams: Promise<{
    view?: string | string[];
    filter?: string | string[];
    date?: string | string[];
  }>;
}

function first(value: string | string[] | undefined): string | undefined {
  if (Array.isArray(value)) return value[0];
  return value;
}

function parseMonthParam(
  raw: string | undefined,
): { year: number; month: number } | null {
  if (!raw) return null;
  const match = /^(\d{4})-(\d{2})$/.exec(raw);
  if (!match) return null;
  const year = Number(match[1]);
  const month = Number(match[2]);
  if (
    !Number.isFinite(year) ||
    !Number.isFinite(month) ||
    month < 1 ||
    month > 12 ||
    year < 1970 ||
    year > 3000
  ) {
    return null;
  }
  return { year, month };
}

export default async function EventsPage({ searchParams }: EventsPageProps) {
  const sp = await searchParams;
  const view = first(sp.view) === "month" ? "month" : "list";
  const filter = first(sp.filter) === "past" ? "past" : "upcoming";
  const dateParam = first(sp.date);

  // Resolve month-view year/month: parse param, or fall back to "now in Chicago".
  const nowChicago = toZonedTime(new Date(), CHICAGO_TZ);
  const currentYear = nowChicago.getFullYear();
  const currentMonth = nowChicago.getMonth() + 1; // 1-indexed

  let monthYear = currentYear;
  let monthMonth = currentMonth;
  if (view === "month") {
    const parsed = parseMonthParam(dateParam);
    if (parsed) {
      monthYear = parsed.year;
      monthMonth = parsed.month;
    }
  }
  const isCurrentMonth =
    monthYear === currentYear && monthMonth === currentMonth;

  return (
    <>
      {/* Page header (matches /sponsors) */}
      <section className="bg-mavs-navy text-white">
        <div className="container mx-auto px-4 py-12 md:py-16">
          <h1 className="text-4xl md:text-5xl font-black uppercase tracking-tight">
            Events
          </h1>
          <div className="h-1 w-20 bg-mavs-green mt-3"></div>
          <p className="text-lg text-white/80 mt-3">
            Booster club events, parent meetings, and team gatherings
          </p>
        </div>
      </section>

      {/* Toolbar */}
      <section className="border-b border-mavs-navy/10 bg-white">
        <div className="container mx-auto px-4 py-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div className="flex items-center gap-6">
            <Link
              href="/events"
              aria-current={view === "list" ? "page" : undefined}
              className={
                view === "list"
                  ? "text-mavs-navy border-b-2 border-mavs-navy pb-1 font-bold uppercase tracking-wide"
                  : "text-muted-foreground hover:text-mavs-navy border-b-2 border-transparent pb-1 font-bold uppercase tracking-wide"
              }
            >
              List
            </Link>
            <Link
              href="/events?view=month"
              aria-current={view === "month" ? "page" : undefined}
              className={
                view === "month"
                  ? "text-mavs-navy border-b-2 border-mavs-navy pb-1 font-bold uppercase tracking-wide"
                  : "text-muted-foreground hover:text-mavs-navy border-b-2 border-transparent pb-1 font-bold uppercase tracking-wide"
              }
            >
              Month
            </Link>
          </div>
          <div className="self-end sm:self-auto">
            <SubscribeButtonShape />
          </div>
        </div>
      </section>

      {view === "month" ? (
        <EventMonthView
          year={monthYear}
          month={monthMonth}
          isCurrentMonth={isCurrentMonth}
        />
      ) : (
        <EventListView filter={filter} />
      )}
    </>
  );
}
