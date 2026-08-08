import Link from "next/link";
import {
  CalendarDays,
  HandHelping,
  Handshake,
  HeartHandshake,
  UserPlus,
  Users,
} from "lucide-react";

import { EventRowCard } from "@/components/events/EventListView";
import { HeroCarousel } from "@/components/home/HeroCarousel";
import { SponsorCarousel } from "@/components/sponsors/SponsorCarousel";
import { getUpcomingEvents } from "@/lib/queries/events";
import { loadHeroCarouselData } from "@/lib/queries/hero";
import { getSiteSettingsCore } from "@/lib/site-settings";
import { createServerClient } from "@/lib/supabase/server";
import type { EventRow } from "@/lib/types";

export const revalidate = 60;

type SponsorTile = {
  id: string;
  name: string;
  logo_url: string | null;
  website_url: string | null;
  tier_id: string | null;
};

type HomeData = {
  events: EventRow[];
  sponsors: SponsorTile[];
};

const EMPTY_HOME: HomeData = {
  events: [],
  sponsors: [],
};

async function loadHome(): Promise<HomeData> {
  try {
    const { current_year } = await getSiteSettingsCore();
    const supabase = createServerClient();

    const [eventsRes, sponsorsRes] = await Promise.all([
      // Shares getUpcomingEvents with /events on purpose. This used to be its own
      // inline `.gte("starts_at", now)` query, which meant the homepage and the
      // events page each owned a private definition of "upcoming" and could
      // disagree about the same event — exactly what happened when the split
      // moved from start-time to end-time (2026-08-08). One decision site now.
      getUpcomingEvents(2),
      supabase
        .from("sponsors")
        .select("id, name, logo_url, website_url, tier_id")
        // Partners (migration 115) are acknowledged only on /boosters/donate.
        // Missing this filter on ANY sponsor surface republishes an in-kind
        // partner as if they had bought a tier — the exact Rudy's failure this
        // project shipped twice. All three surfaces must carry it.
        .eq("kind", "sponsor")
        .eq("active", true)
        .eq("year", current_year)
        .order("sort_order", { ascending: true })
        .order("name", { ascending: true })
        .returns<SponsorTile[]>(),
      // The MVP-tier lookup that used to live here is gone: it existed solely to
      // split the strip into a larger top-tier row, and the strip is now a
      // single-row carousel. One fewer query per homepage render.
    ]);

    return {
      events: eventsRes,
      sponsors:
        sponsorsRes.error || !sponsorsRes.data ? [] : sponsorsRes.data,
    };
  } catch {
    return EMPTY_HOME;
  }
}

// The Schedule and Roster labels are year-stamped from the same settings the
// destination pages read (current_schedule_year / current_roster_year), not
// from current_year -- those years advance independently, so a single
// current_year label would go stale on whichever one moved first.
function buildQuickLinks(
  scheduleYear: string,
  rosterYear: string,
): Array<{
  label: string;
  href: string;
  Icon: React.ComponentType<{ size?: number; className?: string }>;
}> {
  return [
    { label: "Join the Club", href: "/boosters/join", Icon: UserPlus },
    { label: "Sponsor the Team", href: "/boosters/sponsor", Icon: Handshake },
    { label: "Volunteer", href: "/boosters/volunteer", Icon: HandHelping },
    { label: "Make a Donation", href: "/boosters/donate", Icon: HeartHandshake },
    { label: `${scheduleYear} Schedule`, href: "/schedule", Icon: CalendarDays },
    { label: `${rosterYear} Roster`, href: "/roster", Icon: Users },
  ];
}

export default async function Home() {
  // current_year is the sponsors year (see the sponsor strip heading below);
  // the Schedule and Roster tiles use their own decoupled years.
  const { current_schedule_year, current_roster_year, current_year } =
    await getSiteSettingsCore();
  const [{ events, sponsors }, carousel] = await Promise.all([
    loadHome(),
    loadHeroCarouselData(),
  ]);
  const quickLinks = buildQuickLinks(current_schedule_year, current_roster_year);
  return (
    <>
      <HeroCarousel
        backgrounds={carousel.backgrounds}
        tiles={carousel.tiles}
      />

      <section className="bg-mavs-green">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12">
          <h2 className="text-2xl font-bold uppercase tracking-tight mb-6 text-center text-white">
            Get Involved
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {quickLinks.map(({ label, href, Icon }) => (
              <Link
                key={href}
                href={href}
                className="flex flex-col items-center text-center gap-3 rounded-lg border border-border bg-white p-6 hover:border-mavs-navy hover:shadow-md transition-all"
              >
                <Icon size={32} className="text-mavs-navy" />
                <span className="font-medium text-foreground">{label}</span>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {events.length > 0 ? (
        <section className="bg-mavs-green text-white">
          <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12">
            <h2 className="text-2xl font-bold uppercase tracking-tight mb-6 text-center">
              Upcoming Events
            </h2>
            <div>
              {events.map((event) => (
                <EventRowCard
                  key={event.id}
                  event={event}
                  variant="on-green"
                />
              ))}
            </div>
            <div className="text-center mt-8">
              <Link href="/events" className="text-sm font-bold hover:underline">
                All Events →
              </Link>
            </div>
          </div>
        </section>
      ) : null}

      {sponsors.length > 0 ? (
        <section className="container mx-auto px-4 py-12 md:py-16">
          <h2 className="text-2xl md:text-3xl font-bold text-mavs-navy text-center mb-10">
            {/* Year-stamped from current_year (the sponsors year) rather than
                hardcoded -- this read "2025-2026" for a full season after the
                sponsor data moved on, because a literal cannot follow the DB. */}
            Thank You to Our {current_year} Sponsors!
          </h2>
          {/* One row, six at a time, sliding by one every few seconds, all at
              the same size. Replaces the old two-row split that rendered the
              MVP tier larger on its own row — Jeremy wants a single line and
              capped it at six. The biggest supporter stays pinned in slot 1 by
              the carousel so a single row doesn't cost them visibility. */}
          <SponsorCarousel sponsors={sponsors} />
          <div className="text-center mt-10">
            <Link
              href="/sponsors"
              className="text-mavs-navy font-semibold uppercase tracking-wide text-sm hover:text-mavs-green transition-colors"
            >
              See All Sponsors →
            </Link>
          </div>
        </section>
      ) : null}
    </>
  );
}
