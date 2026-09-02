import Image from "next/image";
import { formatInTimeZone } from "date-fns-tz";
import { CalendarCheck, MapPin, Utensils } from "lucide-react";

import {
  TEAM_DINNERS_DATE_ENTRY_ID,
  TEAM_DINNERS_FORM_URL,
} from "@/lib/constants";
import {
  TEAM_DINNER_ADDRESS,
  TEAM_DINNER_BREAKDOWN,
  TEAM_DINNER_DEFAULT_TIME,
  TEAM_DINNER_HEADCOUNT,
  TEAM_DINNER_HOST_PROVIDES,
  TEAM_DINNER_PLACE,
  TEAM_DINNER_ROOM_NOTE,
  TEAM_DINNER_SLOTS,
  TEAM_DINNER_TEAM_UP_EMAIL,
  teamDinnerMapsUrl,
} from "@/lib/team-dinners";
import { CHICAGO_TZ } from "@/lib/events-format";
import { getTeamDinnerSignups } from "@/lib/sheets/team-dinners";

// Availability is filtered against the current time and read from a live sheet,
// so this must not be frozen at build time. 60s keeps the table close to real
// without hitting the Sheets API on every request; the form is the source of
// truth, so a minute of lag only ever costs a "that night was just taken" email.
export const revalidate = 60;

export const metadata = {
  title: "Varsity Team Dinners | McNeil Mavericks Football Booster Club",
  description:
    "Sign up to host a varsity team dinner at McNeil High School the night before a game. The host family brings everything: food, drinks, plates, utensils, and cleanup.",
};

const CONTACT_EMAIL = "boosters@mcneilmavericks.org";

/** Prefilled form link with this date's checkbox already ticked. */
function claimUrl(optionText: string): string {
  const base = TEAM_DINNERS_FORM_URL.replace(/\/viewform.*$/, "/viewform");
  return `${base}?usp=pp_url&entry.${TEAM_DINNERS_DATE_ENTRY_ID}=${encodeURIComponent(optionText)}`;
}

export default async function TeamDinnersPage() {
  const signups = await getTeamDinnerSignups();

  // A night stays listed until the dinner has ENDED, so someone checking their
  // phone at 7:45 on the day still sees the one they are driving to.
  // `new Date()` rather than `Date.now()`: react-hooks/purity rejects the
  // latter in a render, and app/events/page.tsx already set this precedent.
  const now = new Date().getTime();
  const upcoming = TEAM_DINNER_SLOTS.filter(
    (s) => new Date(s.endsAt).getTime() > now,
  );

  const configured =
    !TEAM_DINNERS_FORM_URL.includes("__REPLACE_") &&
    !TEAM_DINNERS_DATE_ENTRY_ID.includes("__REPLACE_");

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
                Varsity Team Dinners
              </h1>
            </div>
            <div className="hidden md:block w-20 shrink-0" aria-hidden="true" />
          </div>
        </div>
      </section>

      <section className="container mx-auto px-4 py-10 md:py-12 max-w-3xl">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            The varsity squad eats together the night before every game. New for
            this season, dinner is at <strong>{TEAM_DINNER_PLACE}</strong> rather
            than at a family&apos;s home: the boys are already on campus, they
            stay to support the freshman and JV game, and not all of them have a
            ride somewhere else and back.
          </p>
          <p>
            One family takes each night, for{" "}
            <strong>about {TEAM_DINNER_HEADCOUNT} people</strong> —{" "}
            {TEAM_DINNER_BREAKDOWN}.
          </p>
          {/* 🚨 Jeremy 2026-09-01: THE HOST BRINGS EVERYTHING, NOT JUST THE
              FOOD. The old copy said "you bring the meal, set it out, and clean
              up after", which reads as food only — and someone turns up with six
              foil trays and nothing to eat off. Spelled out as a list, above the
              night list, so it is unmissable BEFORE anyone claims a night. Do
              not collapse it back into a sentence. */}
          <div className="rounded-lg border-2 border-mavs-navy/25 bg-white p-5">
            <p className="font-bold text-mavs-navy">
              The host family provides everything for the meal, not just the
              food:
            </p>
            <ul className="mt-3 space-y-1.5 text-base">
              {TEAM_DINNER_HOST_PROVIDES.map((item) => (
                <li key={item} className="flex items-start gap-2">
                  <span aria-hidden="true" className="text-mavs-green font-bold">
                    +
                  </span>
                  <span>{item}</span>
                </li>
              ))}
            </ul>
            <p className="mt-3 text-base text-gray-700">
              Nothing is stocked at the school, so plan to bring the whole setup
              with you.
            </p>
          </div>
          {/* ⚠️ Say this before they click, not in the confirmation email. The
              game-day meal program IS parent-funded through the club and these
              two get conflated constantly; someone who assumes reimbursement
              finds out at the register. */}
          <p className="font-semibold text-mavs-navy">
            The host covers the meal. Team dinners are not paid for out of the
            booster club budget, so this is a real out-of-pocket commitment —
            worth knowing up front.
          </p>
          <p>
            Nights below are first come, first served. After you sign up we will
            email you the details and a reminder a week out, so you have time to
            shop.
          </p>
        </div>
      </section>

      <section className="container mx-auto px-4 pb-4 md:pb-6">
        <div className="max-w-4xl mx-auto">
          {!signups.ok ? (
            /* ⚠️ Never render availability we could not verify. Showing every
               night as open would invite people to claim nights that are already
               covered — the exact problem this page exists to solve. */
            <div className="border-2 border-mavs-navy/20 rounded-lg p-6 md:p-8 text-center bg-gray-50">
              <h2 className="text-2xl font-bold text-mavs-navy">
                We can&apos;t load the current signups right now
              </h2>
              <p className="text-gray-700 mt-3 max-w-xl mx-auto">
                Rather than show you nights that might already be taken, we are
                showing nothing at all. Please check back shortly, or email{" "}
                <a
                  href={`mailto:${CONTACT_EMAIL}`}
                  className="font-bold text-mavs-navy underline underline-offset-2"
                >
                  {CONTACT_EMAIL}
                </a>{" "}
                and we will get you on a night.
              </p>
            </div>
          ) : upcoming.length === 0 ? (
            <div className="border-2 border-mavs-navy/20 rounded-lg p-6 md:p-8 text-center bg-gray-50">
              <h2 className="text-2xl font-bold text-mavs-navy">
                That&apos;s a wrap on this season
              </h2>
              <p className="text-gray-700 mt-3">
                Every team dinner has passed. Thank you to every family that fed
                this team.
              </p>
            </div>
          ) : (
            <ul className="space-y-4">
              {upcoming.map((slot) => {
                const claim = signups.claimsByDate.get(slot.date);
                const start = new Date(slot.startsAt);
                const game = new Date(`${slot.gameDate}T12:00:00-05:00`);

                return (
                  <li
                    key={slot.date}
                    className={`border-2 rounded-lg p-5 md:p-6 ${
                      claim
                        ? "border-gray-200 bg-gray-50"
                        : "border-mavs-navy/25 bg-white"
                    }`}
                  >
                    <div className="flex flex-col md:flex-row md:items-center gap-4 md:gap-6">
                      <div className="md:w-44 shrink-0">
                        {/* Weekday is rendered, never assumed. Most of these are
                            Thursdays; Sept 23 is a WEDNESDAY because the Lake
                            Travis game is on a Thursday. */}
                        <p className="font-black uppercase text-mavs-navy text-lg leading-tight">
                          {formatInTimeZone(start, CHICAGO_TZ, "EEEE")}
                        </p>
                        <p className="font-black uppercase text-mavs-navy text-2xl leading-tight">
                          {formatInTimeZone(start, CHICAGO_TZ, "MMMM d")}
                        </p>
                        <p className="text-sm text-gray-600 mt-1">
                          {formatInTimeZone(start, CHICAGO_TZ, "h:mm a")}
                        </p>
                      </div>

                      <div className="flex-1 min-w-0">
                        <p className="font-bold text-mavs-navy text-lg">
                          Before {slot.opponent}
                          {slot.occasion ? (
                            <span className="font-normal text-gray-700">
                              {" "}
                              ({slot.occasion})
                            </span>
                          ) : null}
                        </p>
                        <p className="text-sm text-gray-700 mt-1">
                          Varsity plays{" "}
                          {formatInTimeZone(game, CHICAGO_TZ, "EEEE MMMM d")}.
                        </p>
                        <p className="text-sm text-gray-700 mt-2 flex items-start gap-1.5">
                          <MapPin size={15} className="mt-0.5 shrink-0" aria-hidden="true" />
                          <a
                            href={teamDinnerMapsUrl()}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="hover:text-mavs-navy hover:underline"
                          >
                            {TEAM_DINNER_PLACE}, {TEAM_DINNER_ADDRESS}
                          </a>
                        </p>
                        <p className="text-sm text-gray-700 mt-1 flex items-start gap-1.5">
                          <Utensils size={15} className="mt-0.5 shrink-0" aria-hidden="true" />
                          Food, drinks, plates, utensils and cleanup for about{" "}
                          {TEAM_DINNER_HEADCOUNT}.
                        </p>
                      </div>

                      <div className="md:w-48 shrink-0 md:text-right">
                        {claim ? (
                          <p className="inline-flex items-center gap-2 font-bold text-mavs-green">
                            <CalendarCheck size={18} aria-hidden="true" />
                            Covered by {claim.displayName}
                          </p>
                        ) : configured ? (
                          <a
                            href={claimUrl(slot.optionText)}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-block w-full md:w-auto text-center bg-mavs-green text-white px-6 py-3 font-bold uppercase hover:bg-mavs-green/90 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-mavs-navy focus-visible:ring-offset-2"
                          >
                            Claim this night
                          </a>
                        ) : (
                          <a
                            href={`mailto:${CONTACT_EMAIL}?subject=Varsity%20team%20dinner`}
                            className="inline-block w-full md:w-auto text-center bg-mavs-green text-white px-6 py-3 font-bold uppercase hover:bg-mavs-green/90 transition-colors"
                          >
                            Email to claim
                          </a>
                        )}
                      </div>
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      </section>

      {signups.ok && upcoming.length > 0 && configured ? (
        <section className="container mx-auto px-4 pb-10 md:pb-12">
          <p className="max-w-4xl mx-auto text-center text-gray-700">
            Want more than one night?{" "}
            <a
              href={TEAM_DINNERS_FORM_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="font-bold text-mavs-navy underline underline-offset-2 hover:text-mavs-green"
            >
              Open the form and tick as many as you can cover
            </a>
            .
          </p>
        </section>
      ) : null}

      <section className="container mx-auto px-4 pb-12 md:pb-16 max-w-3xl">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            <strong>Where exactly?</strong> {TEAM_DINNER_ROOM_NOTE}
          </p>
          <p>
            <strong>Times can move.</strong> {TEAM_DINNER_DEFAULT_TIME} is the
            plan, but it is built around the freshman and JV game and Coach may
            shift a week. The time on your night above is the one we have, and
            we will email you if it changes.
          </p>
          {/* 🔁 REVERSAL, AND IT IS DELIBERATE. Jeremy 2026-08-26 had this copy
              STOP promising matchmaking -- the older line ("we will connect you
              with anyone else who offers") created work nobody owned. Jeremy
              2026-09-01 reinstates it WITH AN OWNER: teammeals@ is a real
              address that does the connecting, so the promise now lands
              somewhere. The self-organise guidance stays and is still the
              primary path; the address is the fallback for a family with nobody
              to organise with.
              ⚠️ It is teammeals@, NOT teamdinners@ -- the obvious guess from the
              page title bounces. */}
          <p>
            <strong>Want to team up?</strong> That is the easiest way to do it,
            and most nights get covered by a group — splitting the food, the
            drinks and the supplies across a few families is how it usually
            works. Organize it yourselves with other parents, agree who is
            bringing what, then have one person sign up for the night as the
            lead. That person is our contact and gets the confirmation and
            reminders.
          </p>
          <p>
            <strong>Need someone to team up with?</strong> If you want to share a
            night and do not have anyone lined up — for any week — email{" "}
            <a
              href={`mailto:${TEAM_DINNER_TEAM_UP_EMAIL}?subject=Varsity%20team%20dinner%20-%20looking%20to%20team%20up`}
              className="font-bold text-mavs-navy underline underline-offset-2"
            >
              {TEAM_DINNER_TEAM_UP_EMAIL}
            </a>{" "}
            and we will help connect you with others.
          </p>
          <p>
            <strong>Something come up?</strong> Email{" "}
            <a
              href={`mailto:${CONTACT_EMAIL}`}
              className="font-bold text-mavs-navy underline underline-offset-2"
            >
              {CONTACT_EMAIL}
            </a>{" "}
            and we will reopen your night. As much notice as you can give is
            appreciated, but tell us either way. A night nobody knows is
            uncovered is much worse than one we can hand to someone else.
          </p>
          <p>
            Didn&apos;t get a confirmation email within a few minutes? Check your
            spam, then email us. It usually means a typo in the address, and
            without it you will not get your reminders either.
          </p>
        </div>
      </section>
    </>
  );
}
