import Link from "next/link";
import {
  CalendarDays,
  HandHelping,
  Handshake,
  HeartHandshake,
  UserPlus,
  Users,
} from "lucide-react";

import { HeroCarousel } from "@/components/home/HeroCarousel";
import { SponsorStripLogo } from "@/components/sponsors/SponsorStripLogo";
import { loadHeroCarouselData } from "@/lib/queries/hero";
import { getSiteSettingsCore } from "@/lib/site-settings";
import { createServerClient } from "@/lib/supabase/server";

export const revalidate = 60;

type NewsCard = {
  id: string;
  slug: string;
  title: string;
  excerpt: string | null;
  featured_image_url: string | null;
  published_at: string | null;
};

type EventCard = {
  id: string;
  slug: string;
  title: string;
  starts_at: string;
  location: string | null;
};

type SponsorTile = {
  id: string;
  name: string;
  logo_url: string | null;
  website_url: string | null;
  tier_id: string | null;
};

type HomeData = {
  news: NewsCard[];
  events: EventCard[];
  sponsors: SponsorTile[];
  mvpTierId: string | null;
};

const EMPTY_HOME: HomeData = {
  news: [],
  events: [],
  sponsors: [],
  mvpTierId: null,
};

function formatDate(iso: string | null | undefined): string {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  return d.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

async function loadHome(): Promise<HomeData> {
  try {
    const { current_year } = await getSiteSettingsCore();
    const supabase = createServerClient();
    const nowIso = new Date().toISOString();

    const [newsRes, eventsRes, sponsorsRes, mvpTierRes] = await Promise.all([
      supabase
        .from("news_posts")
        .select("id, slug, title, excerpt, featured_image_url, published_at")
        .eq("status", "published")
        .order("published_at", { ascending: false })
        .limit(3)
        .returns<NewsCard[]>(),
      supabase
        .from("events")
        .select("id, slug, title, starts_at, location")
        .eq("status", "published")
        .gt("starts_at", nowIso)
        .order("starts_at", { ascending: true })
        .limit(5)
        .returns<EventCard[]>(),
      supabase
        .from("sponsors")
        .select("id, name, logo_url, website_url, tier_id")
        .eq("active", true)
        .eq("year", current_year)
        .order("sort_order", { ascending: true })
        .order("name", { ascending: true })
        .returns<SponsorTile[]>(),
      supabase
        .from("sponsorship_tiers")
        .select("id")
        .eq("year", current_year)
        .eq("active", true)
        .eq("name", "MVP")
        .maybeSingle(),
    ]);

    if (mvpTierRes.error) {
      console.error("Failed to load MVP tier:", mvpTierRes.error);
    }

    return {
      news: newsRes.error || !newsRes.data ? [] : newsRes.data,
      events: eventsRes.error || !eventsRes.data ? [] : eventsRes.data,
      sponsors:
        sponsorsRes.error || !sponsorsRes.data ? [] : sponsorsRes.data,
      mvpTierId:
        mvpTierRes.error || !mvpTierRes.data ? null : mvpTierRes.data.id,
    };
  } catch {
    return EMPTY_HOME;
  }
}

function buildQuickLinks(currentYear: string): Array<{
  label: string;
  href: string;
  Icon: React.ComponentType<{ size?: number; className?: string }>;
}> {
  return [
    { label: "Join the Club", href: "/boosters/join", Icon: UserPlus },
    { label: "Sponsor the Team", href: "/boosters/sponsor", Icon: Handshake },
    { label: "Volunteer", href: "/boosters/volunteer", Icon: HandHelping },
    { label: "Make a Donation", href: "/boosters/donate", Icon: HeartHandshake },
    { label: `${currentYear} Schedule`, href: "/schedule", Icon: CalendarDays },
    { label: `${currentYear} Roster`, href: "/roster", Icon: Users },
  ];
}

export default async function Home() {
  const { current_year } = await getSiteSettingsCore();
  const [{ news, events, sponsors, mvpTierId }, carousel] = await Promise.all([
    loadHome(),
    loadHeroCarouselData(),
  ]);
  const quickLinks = buildQuickLinks(current_year);
  const topTierSponsors = mvpTierId
    ? sponsors.filter((s) => s.tier_id === mvpTierId)
    : [];
  const otherSponsors = mvpTierId
    ? sponsors.filter((s) => s.tier_id !== mvpTierId)
    : sponsors;

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

      {news.length > 0 ? (
        <section className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold uppercase tracking-tight">Latest News</h2>
            <Link
              href="/news"
              className="text-sm font-medium text-mavs-navy hover:underline"
            >
              View all news →
            </Link>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {news.map((post) => (
              <Link
                key={post.id}
                href={`/news/${post.slug}`}
                className="block rounded-lg border border-border bg-white overflow-hidden hover:shadow-md transition-shadow"
              >
                {post.featured_image_url ? (
                  <div className="aspect-[16/9] bg-muted overflow-hidden">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={post.featured_image_url}
                      alt=""
                      className="h-full w-full object-cover"
                    />
                  </div>
                ) : null}
                <div className="p-4">
                  <p className="text-xs text-muted-foreground">
                    {formatDate(post.published_at)}
                  </p>
                  <h3 className="mt-1 font-semibold text-foreground">
                    {post.title}
                  </h3>
                  {post.excerpt ? (
                    <p className="mt-2 text-sm text-muted-foreground line-clamp-3">
                      {post.excerpt}
                    </p>
                  ) : null}
                </div>
              </Link>
            ))}
          </div>
        </section>
      ) : null}

      {events.length > 0 ? (
        <section className="bg-muted/40">
          <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-12">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold uppercase tracking-tight">
                Upcoming Events
              </h2>
              <Link
                href="/boosters/events"
                className="text-sm font-medium text-mavs-navy hover:underline"
              >
                View calendar →
              </Link>
            </div>
            <ul className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 list-none p-0">
              {events.map((ev) => (
                <li
                  key={ev.id}
                  className="rounded-lg border border-border bg-white p-4"
                >
                  <p className="text-xs uppercase tracking-wide text-mavs-navy font-semibold">
                    {formatDate(ev.starts_at)}
                  </p>
                  <p className="mt-2 font-semibold text-foreground">
                    {ev.title}
                  </p>
                  {ev.location ? (
                    <p className="text-sm text-muted-foreground mt-1">
                      {ev.location}
                    </p>
                  ) : null}
                  {ev.slug ? (
                    <p className="mt-3">
                      <Link
                        href={`/boosters/events/${ev.slug}`}
                        className="text-sm font-medium text-mavs-navy hover:underline"
                      >
                        Learn more →
                      </Link>
                    </p>
                  ) : null}
                </li>
              ))}
            </ul>
          </div>
        </section>
      ) : null}

      {sponsors.length > 0 ? (
        <section className="container mx-auto px-4 py-12 md:py-16">
          <h2 className="text-2xl md:text-3xl font-bold text-mavs-navy text-center mb-10">
            Thank You to Our 2025-2026 Sponsors!
          </h2>
          {topTierSponsors.length > 0 ? (
            <div className="flex flex-wrap items-center justify-center gap-12 mb-8">
              {topTierSponsors.map((s) => (
                <SponsorStripLogo
                  key={s.id}
                  sponsor={s}
                  sizeClass="max-w-[220px] max-h-20"
                />
              ))}
            </div>
          ) : null}
          {otherSponsors.length > 0 ? (
            <div className="flex flex-wrap items-center justify-center gap-8 md:gap-12">
              {otherSponsors.map((s) => (
                <SponsorStripLogo
                  key={s.id}
                  sponsor={s}
                  sizeClass="max-w-[160px] max-h-12"
                />
              ))}
            </div>
          ) : null}
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
