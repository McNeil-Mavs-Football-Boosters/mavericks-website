import Link from "next/link";
import { notFound } from "next/navigation";
import { Camera } from "lucide-react";
import { formatInTimeZone } from "date-fns-tz";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

import { getEventBySlug } from "@/lib/queries/events";
import { CHICAGO_TZ } from "@/lib/events-format";

export const dynamic = "force-dynamic";

/**
 * Detail-page headline date/time range. Uses year-bearing format (distinct from
 * the list-view formatTimeRange in lib/events-format.ts which omits the year).
 *
 *   No ends_at:                       "May 26, 2026 @ 7:00 PM"
 *   Same Chicago calendar day:        "May 26, 2026 @ 7:00 PM – 8:30 PM"
 *   Different Chicago calendar days:  "September 10, 2026 @ 5:00 PM – September 12, 2026 @ 12:00 PM"
 */
function formatDetailTimeRange(
  startsAt: string,
  endsAt: string | null,
): string {
  const start = new Date(startsAt);
  const startLabel = formatInTimeZone(
    start,
    CHICAGO_TZ,
    "MMMM d, yyyy @ h:mm a",
  );

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

  const endLabel = formatInTimeZone(end, CHICAGO_TZ, "MMMM d, yyyy @ h:mm a");
  return `${startLabel} – ${endLabel}`;
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const event = await getEventBySlug(slug);
  if (!event) {
    return { title: "Event | McNeil Mavericks Football" };
  }
  const description = (event.description ?? "").trim();
  return {
    title: `${event.title} | McNeil Mavericks Football`,
    description: description
      ? description.slice(0, 160)
      : `${event.title} — McNeil Mavericks Football booster club event.`,
  };
}

export default async function EventDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const event = await getEventBySlug(slug);
  if (!event) notFound();

  const dateTimeLabel = formatDetailTimeRange(event.starts_at, event.ends_at);
  const description = (event.description ?? "").trim();

  return (
    <>
      {/* Page header (matches /sponsors) */}
      <section className="bg-mavs-navy text-white">
        <div className="container mx-auto px-4 py-12 md:py-16">
          <h1 className="text-4xl md:text-5xl font-black uppercase tracking-tight">
            {event.title}
          </h1>
          <div className="h-1 w-20 bg-mavs-green mt-3"></div>
          <p className="text-lg text-white/80 mt-3">{dateTimeLabel}</p>
          {event.location ? (
            <p className="text-lg text-white/80 mt-1">{event.location}</p>
          ) : null}
        </div>
      </section>

      {/* Cover image */}
      {event.cover_image_url ? (
        <section className="container mx-auto px-4 py-8">
          <div className="max-w-4xl mx-auto">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={event.cover_image_url}
              alt=""
              className="w-full aspect-video object-cover rounded-lg"
            />
          </div>
        </section>
      ) : null}

      {/* Description body (markdown) */}
      {description ? (
        <section className="container mx-auto px-4 py-8">
          <div className="max-w-4xl mx-auto prose prose-neutral max-w-none [&_h1]:text-2xl [&_h1]:font-semibold [&_h1]:mt-4 [&_h1]:mb-2 [&_h2]:text-xl [&_h2]:font-semibold [&_h2]:mt-4 [&_h2]:mb-2 [&_h3]:font-semibold [&_h3]:mt-3 [&_h3]:mb-1 [&_p]:mb-3 [&_ul]:list-disc [&_ul]:pl-6 [&_ul]:mb-3 [&_ol]:list-decimal [&_ol]:pl-6 [&_ol]:mb-3 [&_a]:text-mavs-navy [&_a]:underline [&_table]:w-full [&_table]:my-3 [&_th]:text-left [&_th]:py-1 [&_td]:py-1 [&_th]:border-b [&_td]:border-b [&_th]:border-border [&_td]:border-border">
            <ReactMarkdown remarkPlugins={[remarkGfm]}>
              {description}
            </ReactMarkdown>
          </div>
        </section>
      ) : null}

      {/* Location card */}
      {event.location ? (
        <section className="container mx-auto px-4 py-8">
          <div className="max-w-4xl mx-auto bg-white border border-mavs-navy/10 rounded-lg p-6">
            <h2 className="text-xl font-bold text-mavs-navy uppercase tracking-tight">
              Location
            </h2>
            <p className="font-bold mt-3">{event.location}</p>
            {event.venue?.maps_url ? (
              <a
                href={event.venue.maps_url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-mavs-navy hover:underline mt-2 inline-block"
              >
                Get directions →
              </a>
            ) : null}
          </div>
        </section>
      ) : null}

      {/* Sign-up CTA. The label is per-row (migration 149): most destinations are
          Google Forms and default to "Sign Up", but Picture Day points at the
          photographer's store, where "Sign Up" would misdescribe a checkout.
          Falls back to the original string so the three existing signup_url
          events render exactly as they always have. */}
      {event.signup_url ? (
        <section className="container mx-auto px-4 py-8">
          <div className="max-w-4xl mx-auto">
            <a
              href={event.signup_url}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-block bg-mavs-navy text-white px-8 py-3 font-bold uppercase hover:bg-mavs-navy/90 transition-colors"
            >
              {event.signup_label ?? "Sign Up"} →
              <span className="sr-only">(opens in a new tab)</span>
            </a>
          </div>
        </section>
      ) : null}

      {/* Photo album. Green rather than navy so it reads as a distinct action
          from Sign Up, since a past event can carry both. Renders only when
          photos_url is set (migration 114). */}
      {event.photos_url ? (
        <section className="container mx-auto px-4 py-8">
          <div className="max-w-4xl mx-auto">
            <a
              href={event.photos_url}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 bg-mavs-green text-white px-8 py-3 font-bold uppercase hover:bg-mavs-green/90 transition-colors"
            >
              <Camera className="h-5 w-5" aria-hidden="true" />
              View Photos
              <span className="sr-only">(opens in a new tab)</span>
            </a>
          </div>
        </section>
      ) : null}

      {/* Back link */}
      <section className="container mx-auto px-4 py-8">
        <div className="max-w-4xl mx-auto">
          <Link href="/events" className="text-mavs-navy hover:underline">
            ← Back to all events
          </Link>
        </div>
      </section>
    </>
  );
}
