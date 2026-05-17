import Image from "next/image";
import Link from "next/link";
import {
  CalendarDays,
  HandHelping,
  Handshake,
  HeartHandshake,
  UserPlus,
  Users,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { getSiteSettingsCore } from "@/lib/site-settings";
import { createServerClient } from "@/lib/supabase/server";
import type { SiteSettings } from "@/lib/types";

export const revalidate = 60;

type HeroFields = Pick<
  SiteSettings,
  | "hero_image_url"
  | "hero_headline"
  | "hero_subhead"
  | "primary_cta_label"
  | "primary_cta_url"
>;

const HERO_DEFAULTS: HeroFields = {
  hero_image_url: null,
  hero_headline: "McNeil Mavericks Football",
  hero_subhead: "Home of the McNeil Mavericks · Austin, TX",
  primary_cta_label: "Join the Booster Club",
  primary_cta_url: "/boosters/join",
};

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
};

type HomeData = {
  hero: HeroFields;
  news: NewsCard[];
  events: EventCard[];
  sponsors: SponsorTile[];
};

const EMPTY_HOME: HomeData = {
  hero: HERO_DEFAULTS,
  news: [],
  events: [],
  sponsors: [],
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

function mergeHero(data: Partial<HeroFields> | null | undefined): HeroFields {
  if (!data) return HERO_DEFAULTS;
  return {
    hero_image_url: data.hero_image_url ?? null,
    hero_headline: data.hero_headline || HERO_DEFAULTS.hero_headline,
    hero_subhead: data.hero_subhead ?? HERO_DEFAULTS.hero_subhead,
    primary_cta_label:
      data.primary_cta_label || HERO_DEFAULTS.primary_cta_label,
    primary_cta_url: data.primary_cta_url || HERO_DEFAULTS.primary_cta_url,
  };
}

async function loadHome(): Promise<HomeData> {
  try {
    const { current_year } = await getSiteSettingsCore();
    const supabase = createServerClient();
    const nowIso = new Date().toISOString();

    const [heroRes, newsRes, eventsRes, sponsorsRes] = await Promise.all([
      supabase
        .from("site_settings")
        .select(
          "hero_image_url, hero_headline, hero_subhead, primary_cta_label, primary_cta_url",
        )
        .eq("id", 1)
        .single<HeroFields>(),
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
        .select("id, name, logo_url, website_url")
        .eq("active", true)
        .eq("year", current_year)
        .order("sort_order", { ascending: true })
        .order("name", { ascending: true })
        .returns<SponsorTile[]>(),
    ]);

    return {
      hero: heroRes.error ? HERO_DEFAULTS : mergeHero(heroRes.data),
      news: newsRes.error || !newsRes.data ? [] : newsRes.data,
      events: eventsRes.error || !eventsRes.data ? [] : eventsRes.data,
      sponsors:
        sponsorsRes.error || !sponsorsRes.data ? [] : sponsorsRes.data,
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
    { label: "Make a Donation", href: "/boosters/donate", Icon: HeartHandshake },
    { label: "Volunteer", href: "/boosters/volunteer", Icon: HandHelping },
    { label: `${currentYear} Schedule`, href: "/schedule", Icon: CalendarDays },
    { label: `${currentYear} Roster`, href: "/roster", Icon: Users },
  ];
}

export default async function Home() {
  const { current_year } = await getSiteSettingsCore();
  const { hero, news, events, sponsors } = await loadHome();
  const quickLinks = buildQuickLinks(current_year);
  const hasHeroImage = Boolean(hero.hero_image_url);

  return (
    <>
      <section
        className={`relative isolate w-full min-h-[60vh] md:min-h-[70vh] flex items-center justify-center text-center text-white ${
          hasHeroImage ? "" : "bg-mavs-green"
        }`}
      >
        {hasHeroImage && hero.hero_image_url ? (
          <>
            <Image
              src={hero.hero_image_url}
              alt=""
              fill
              priority
              className="object-cover -z-10"
            />
            <div
              className="absolute inset-0 -z-10 bg-black/50"
              aria-hidden="true"
            />
          </>
        ) : null}

        <div className="mx-auto max-w-3xl px-6 py-24">
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl">
            {hero.hero_headline}
          </h1>
          {hero.hero_subhead ? (
            <p className="mt-4 text-lg sm:text-xl text-white/90">
              {hero.hero_subhead}
            </p>
          ) : null}
          <div className="mt-8 flex justify-center">
            <Button
              size="lg"
              nativeButton={false}
              className="bg-white text-mavs-green hover:bg-white/90"
              render={<Link href={hero.primary_cta_url} />}
            >
              {hero.primary_cta_label}
            </Button>
          </div>
        </div>
      </section>

      <section className="bg-muted/40">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 py-12">
          <h2 className="text-2xl font-bold tracking-tight mb-6 text-center">
            Get Involved
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {quickLinks.map(({ label, href, Icon }) => (
              <Link
                key={href}
                href={href}
                className="flex flex-col items-center text-center gap-3 rounded-lg border border-border bg-white p-6 hover:border-mavs-green hover:shadow-md transition-all"
              >
                <Icon size={32} className="text-mavs-green" />
                <span className="font-medium text-foreground">{label}</span>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {news.length > 0 ? (
        <section className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 py-12">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold tracking-tight">Latest News</h2>
            <Link
              href="/news"
              className="text-sm font-medium text-mavs-green hover:underline"
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
          <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 py-12">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold tracking-tight">
                Upcoming Events
              </h2>
              <Link
                href="/boosters/events"
                className="text-sm font-medium text-mavs-green hover:underline"
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
                  <p className="text-xs uppercase tracking-wide text-mavs-green font-semibold">
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
                        className="text-sm font-medium text-mavs-green hover:underline"
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
        <section className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 py-12">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold tracking-tight">
              Thank You to Our Sponsors
            </h2>
            <Link
              href="/sponsors"
              className="text-sm font-medium text-mavs-green hover:underline"
            >
              See all sponsors →
            </Link>
          </div>
          <div className="flex flex-wrap items-center justify-center gap-8">
            {sponsors.map((s) => {
              const inner = s.logo_url ? (
                /* eslint-disable-next-line @next/next/no-img-element */
                <img
                  src={s.logo_url}
                  alt={s.name}
                  className="h-16 w-auto object-contain"
                />
              ) : (
                <span className="text-sm text-muted-foreground font-medium">
                  {s.name}
                </span>
              );
              return s.website_url ? (
                <a
                  key={s.id}
                  href={s.website_url}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {inner}
                </a>
              ) : (
                <span key={s.id}>{inner}</span>
              );
            })}
          </div>
        </section>
      ) : null}
    </>
  );
}
