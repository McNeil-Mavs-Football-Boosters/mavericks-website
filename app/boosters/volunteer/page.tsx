import Image from "next/image";
import Link from "next/link";
import { formatInTimeZone } from "date-fns-tz";
import {
  ArrowUpRight,
  Award,
  Camera,
  Clipboard,
  Coffee,
  Flag,
  HandCoins,
  HeartHandshake,
  Pizza,
  Ruler,
  Store,
  Users,
  Utensils,
  type LucideIcon,
} from "lucide-react";

import { CHICAGO_TZ } from "@/lib/events-format";
import {
  TUNNEL_VOLUNTEER_FORM_URL,
  VOLUNTEER_FORM_URL,
} from "@/lib/constants";

// The shift list is filtered against the current time on every request, so this
// page must not be statically rendered at build time or it would freeze the
// "upcoming" set forever and keep advertising shifts that already happened.
export const dynamic = "force-dynamic";

export const metadata = {
  title: "Volunteer | McNeil Mavericks Football Booster Club",
  description:
    "Volunteer with the McNeil Football Booster Club. Help feed the team, support coaches, run events, and more.",
};

/**
 * Q2 Stadium concession shifts. Volunteers work a stand at a Q2 event and the
 * proceeds come back to the football booster club.
 *
 * ⚠️ Sign-ups go to the BASEBALL booster treasurer. That is not a mistake:
 * McNeil baseball coordinates the volunteer scheduling for every one of these
 * dates and our shifts still credit football. The page says so out loud,
 * because an unexplained baseball address on a football site reads as a typo
 * and costs sign-ups.
 *
 * ⚠️ TIMEZONE. Daylight saving ends Sun Nov 1 2026, so every shift through
 * Oct 28 is CDT (-05:00) and the Nov 7 shift is CST (-06:00). That is also why
 * Nov 7 starts 90 minutes earlier than the rest: it gets dark sooner. Do not
 * "normalize" these offsets to match.
 *
 * Source: Marcus Horton, the club's Q2 volunteer contact, 2026-08-16.
 */
const Q2_SHIFTS: { startsAt: string; endsAt: string }[] = [
  { startsAt: "2026-08-22T17:00:00-05:00", endsAt: "2026-08-22T22:00:00-05:00" },
  { startsAt: "2026-09-05T17:00:00-05:00", endsAt: "2026-09-05T22:00:00-05:00" },
  { startsAt: "2026-09-09T17:00:00-05:00", endsAt: "2026-09-09T22:00:00-05:00" },
  { startsAt: "2026-09-26T17:00:00-05:00", endsAt: "2026-09-26T22:00:00-05:00" },
  { startsAt: "2026-10-10T17:00:00-05:00", endsAt: "2026-10-10T22:00:00-05:00" },
  { startsAt: "2026-10-17T17:00:00-05:00", endsAt: "2026-10-17T22:00:00-05:00" },
  { startsAt: "2026-10-28T17:00:00-05:00", endsAt: "2026-10-28T22:00:00-05:00" },
  { startsAt: "2026-11-07T15:30:00-06:00", endsAt: "2026-11-07T20:30:00-06:00" },
];

const Q2_SIGNUP_EMAIL = "treasurer@mcneilbaseball.com";

interface Opportunity {
  icon: LucideIcon;
  title: string;
  description: string;
  // Optional per-role sign-up form. Omit to fall back to the general
  // volunteer-interest form, which is where most roles collect interest.
  formUrl?: string;
  // Optional internal destination (a route or an on-page "#anchor"). When set
  // the card renders as an in-site link instead of an external form link.
  href?: string;
}

const OPPORTUNITIES: Opportunity[] = [
  {
    icon: Utensils,
    title: "Hosting a Varsity Team Dinner",
    description:
      "The varsity squad eats together the night before every game, on campus at McNeil rather than at a family's home. One family brings the meal for about 50, sets it out, and cleans up after. See which nights are still open.",
    href: "/boosters/team-dinners",
  },
  {
    icon: Coffee,
    title: "Picking Up Coaches Meals",
    description:
      "A restaurant donates lunch for the coaching staff the Sunday before each varsity game. Pick it up, drop it off between 12:30 and 1:00. See which Sundays are still open.",
    href: "/boosters/coach-meals",
  },
  {
    icon: Pizza,
    title: "Picking Up Game-Day Meals",
    description:
      "Help feed the team before games with quick pickup and delivery shifts.",
  },
  {
    icon: Ruler,
    title: "Freshman / JV Chain Gang",
    description:
      "Work the chain crew on the sideline at Freshman and JV home games.",
  },
  {
    icon: Award,
    title: "Banquets & Player Recognition",
    description:
      "Help plan and run the football banquet, senior night, and other recognition events.",
  },
  {
    icon: HandCoins,
    title: "Fundraising",
    description:
      "Pitch in on fundraisers that keep the booster club going year-round.",
  },
  {
    icon: Users,
    title: "Joining a Committee",
    description:
      "Plug into one of our 11 committees for a deeper, ongoing role.",
    href: "/boosters/committees",
  },
  {
    icon: Store,
    title: "Q2 Stadium Concessions",
    description:
      "Work a concession stand at a Q2 Stadium event. Every dollar raised comes back to the football booster club. No experience needed, and one date is a real help.",
    href: "#q2-concessions",
  },
  {
    icon: Flag,
    title: "Game-Day Tunnel Crew",
    description:
      "Every regular-season varsity game, home and away. Arrive an hour before kickoff to inflate the tunnel, run it through halftime, then tear down and return it to storage.",
    formUrl: TUNNEL_VOLUNTEER_FORM_URL,
  },
  {
    icon: Clipboard,
    title: "Game-Day General Support",
    description:
      "Be a flexible extra hand on game days wherever the team needs help.",
  },
  {
    icon: Camera,
    title: "Communications",
    description:
      "Support team photos, social media posts, or website updates.",
  },
  {
    icon: HeartHandshake,
    title: "General Volunteer",
    description:
      "Not sure where to plug in? Tell us a bit about yourself and we'll find a fit.",
  },
];

// Async server component, matching app/events/page.tsx. Reading the clock is
// what makes this page time-dependent, and the react-hooks/purity rule
// (correctly) rejects that inside a synchronous component render.
export default async function BoostersVolunteerPage() {
  // A shift stays listed until it has finished, so someone checking their phone
  // during an event still sees the one they are standing in. Once the last date
  // passes both the section and its card disappear together, which is what
  // keeps the "#q2-concessions" anchor from ever pointing at nothing.
  const now = new Date().getTime();
  const upcomingShifts = Q2_SHIFTS.filter(
    (shift) => new Date(shift.endsAt).getTime() > now,
  );
  const opportunities = OPPORTUNITIES.filter(
    (opportunity) =>
      opportunity.href !== "#q2-concessions" || upcomingShifts.length > 0,
  );

  return (
    <>
      <section className="bg-mavs-green text-white py-12 md:py-16">
        <div className="container mx-auto px-4">
          <div className="flex flex-col md:flex-row md:items-center gap-4 md:gap-6">
            <Image
              src="/brand/mhs-logo.png"
              alt="McNeil Mavericks logo"
              width={80}
              height={80}
              priority
              className="h-16 w-16 md:h-20 md:w-20 object-contain shrink-0 rounded-full bg-white p-0.5 mx-auto md:mx-0"
            />
            <div className="flex-1 text-center">
              <h1 className="text-4xl md:text-6xl font-black uppercase tracking-tight">
                Volunteer with McNeil Football
              </h1>
            </div>
            <a
              href={VOLUNTEER_FORM_URL}
              target="_blank"
              rel="noopener"
              className="bg-mavs-navy text-white px-6 py-3 font-bold uppercase hover:bg-mavs-navy/90 transition-colors inline-block whitespace-nowrap shrink-0 text-center w-full md:w-auto focus:outline-none focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-mavs-green"
            >
              Sign Up →
            </a>
          </div>
        </div>
      </section>

      <section className="container mx-auto px-4 py-10 md:py-12 max-w-3xl">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            McNeil Football is powered by more than the players and coaches on
            the field. It is also powered by the parents, families, and
            volunteers who give their time behind the scenes to make the season
            meaningful for our athletes.
          </p>
          <p>
            Every meal served, every pickup made, every event organized, and
            every hour volunteered helps create the kind of program our players
            deserve. These moments may seem small, but they add up to something
            our athletes feel throughout the season: support.
          </p>
          <p>
            The McNeil Football Booster Club offers several ways for families
            and community members to get involved. Whether you can help once, a
            few times, or throughout the season, your time makes a difference.
          </p>
        </div>
      </section>

      <section className="container mx-auto px-4 py-8 md:py-12">
        <div className="text-center mb-8">
          <h2 className="text-3xl md:text-4xl font-bold text-mavs-navy">
            Ways to Get Involved
          </h2>
          <p className="text-lg text-gray-600 mt-3">
            Volunteer opportunities may include:
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {opportunities.map((opportunity) => {
            const Icon = opportunity.icon;
            const cardClass =
              "relative bg-white border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow block";

            const cardBody = (
              <>
                <ArrowUpRight
                  aria-hidden="true"
                  className="absolute top-4 right-4 text-mavs-navy"
                  size={20}
                />
                <Icon
                  aria-hidden="true"
                  size={32}
                  className="text-mavs-navy mb-3"
                />
                <h3 className="font-bold text-lg text-mavs-navy">
                  {opportunity.title}
                </h3>
                <p className="text-gray-600 text-sm mt-2">
                  {opportunity.description}
                </p>
              </>
            );

            if (opportunity.href) {
              return (
                <Link
                  key={opportunity.title}
                  href={opportunity.href}
                  className={cardClass}
                >
                  {cardBody}
                </Link>
              );
            }

            return (
              <a
                key={opportunity.title}
                href={opportunity.formUrl ?? VOLUNTEER_FORM_URL}
                target="_blank"
                rel="noopener"
                className={cardClass}
              >
                {cardBody}
              </a>
            );
          })}
        </div>
      </section>

      {upcomingShifts.length > 0 && (
        <section
          id="q2-concessions"
          className="scroll-mt-24 bg-gray-50 border-y border-gray-200 py-10 md:py-14"
        >
          <div className="container mx-auto px-4 max-w-3xl">
            <h2 className="text-3xl md:text-4xl font-bold text-mavs-navy">
              Q2 Stadium Concessions
            </h2>
            <div className="space-y-4 text-lg leading-relaxed text-gray-800 mt-4">
              <p>
                Working a concession stand at Q2 Stadium is one of the easiest
                ways to put real money into this program, and every dollar
                raised goes straight to the football booster club. No experience
                needed, and you do not have to commit to more than one date.
              </p>
              <p>
                Times below are the full window, from when you park to when you
                walk out.
              </p>
            </div>

            <ul className="mt-6 divide-y divide-gray-200 border-y border-gray-200">
              {upcomingShifts.map((shift, index) => (
                <li
                  key={shift.startsAt}
                  className={`flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 py-3 ${
                    index === 0 ? "font-bold text-mavs-green" : "text-gray-800"
                  }`}
                >
                  <span>
                    {formatInTimeZone(
                      new Date(shift.startsAt),
                      CHICAGO_TZ,
                      "EEEE, MMMM d",
                    )}
                  </span>
                  <span className="tabular-nums">
                    {formatInTimeZone(
                      new Date(shift.startsAt),
                      CHICAGO_TZ,
                      "h:mm a",
                    )}{" "}
                    to{" "}
                    {formatInTimeZone(
                      new Date(shift.endsAt),
                      CHICAGO_TZ,
                      "h:mm a",
                    )}
                  </span>
                </li>
              ))}
            </ul>

            <div className="space-y-4 text-lg leading-relaxed text-gray-800 mt-6">
              <p>
                To sign up for any of these, email{" "}
                <a
                  href={`mailto:${Q2_SIGNUP_EMAIL}?subject=Q2%20Concessions%20Volunteer%20(McNeil%20Football)`}
                  className="font-bold text-mavs-navy underline underline-offset-2 hover:text-mavs-green"
                >
                  {Q2_SIGNUP_EMAIL}
                </a>
                . That is not a typo. McNeil baseball coordinates the volunteer
                scheduling for all of these dates, and our shifts still credit
                football.
              </p>
            </div>

            <a
              href={`mailto:${Q2_SIGNUP_EMAIL}?subject=Q2%20Concessions%20Volunteer%20(McNeil%20Football)`}
              className="inline-block mt-6 bg-mavs-green text-white px-8 py-4 font-bold uppercase hover:bg-mavs-green/90 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-mavs-navy focus-visible:ring-offset-2"
            >
              Email to Sign Up →
            </a>
          </div>
        </section>
      )}

      <section className="container mx-auto px-4 py-10 md:py-12 max-w-3xl">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            You do not need to have a specific skill or a large amount of time
            to help. Some roles take planning and coordination, while others may
            only take a quick pickup or a short shift. What matters most is that
            our players see their community showing up for them.
          </p>
          <p>
            When you volunteer with McNeil Football, you are helping feed the
            team, support the coaches, celebrate the players, and build the
            kind of football experience our athletes will remember long after
            the season ends.
          </p>
          <p>
            Your time matters. Your help is appreciated. And every volunteer
            makes McNeil Football stronger.
          </p>
        </div>
        {/* Cross-link to employer matching, added 2026-08-25. This lives on the
            volunteer page on purpose: someone reading it is already thinking
            about hours, which is exactly what a volunteer grant pays on. The
            legal name and EIN are NOT repeated here -- they live in one place on
            /boosters/donate so there is a single copy to keep correct. */}
        <div className="mt-8 bg-mavs-navy/5 border-2 border-mavs-navy/10 rounded-lg p-6 md:p-8">
          <h2 className="text-xl md:text-2xl font-black uppercase tracking-tight text-mavs-navy">
            Your Hours May Be Worth Money
          </h2>
          <p className="text-base leading-relaxed text-gray-800 mt-3">
            Some employers make a donation to the nonprofits their people
            volunteer with, based on the hours you put in. If your company has a
            program like that, the shifts you are already working can turn into
            real money for McNeil football.
          </p>
          <Link
            href="/boosters/donate#employer-matching"
            className="inline-block mt-4 font-bold uppercase text-sm text-mavs-navy underline hover:text-mavs-green"
          >
            How employer matching works →
          </Link>
        </div>
      </section>

      <section className="bg-mavs-navy text-white py-12 md:py-16">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-3xl md:text-4xl font-bold">Ready to Help?</h2>
          <p className="text-lg text-white/90 mt-4 max-w-xl mx-auto">
            Fill out the volunteer interest form and we&apos;ll be in touch.
          </p>
          <a
            href={VOLUNTEER_FORM_URL}
            target="_blank"
            rel="noopener"
            className="inline-block mt-8 bg-mavs-green text-white px-8 py-4 font-bold uppercase hover:bg-mavs-green/90 transition-colors text-lg focus:outline-none focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-mavs-navy"
          >
            Sign Up →
          </a>
        </div>
      </section>
    </>
  );
}
