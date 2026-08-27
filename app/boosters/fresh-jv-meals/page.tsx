import Image from "next/image";
import { formatInTimeZone } from "date-fns-tz";
import { CalendarCheck, MapPin, Utensils } from "lucide-react";

import {
  FRESH_JV_MEALS_DATE_ENTRY_ID,
  FRESH_JV_MEALS_FORM_URL,
} from "@/lib/constants";
import {
  FRESH_JV_MEAL_CONTACT,
  FRESH_JV_MEAL_DROPOFF_CONFIRMED,
  FRESH_JV_MEAL_DROPOFF_PLACE,
  FRESH_JV_MEAL_PICKUP_ADDRESS,
  FRESH_JV_MEAL_PICKUP_PLACE,
  FRESH_JV_MEAL_DROPOFF_TIME,
  FRESH_JV_MEAL_PICKUP_TIME,
  FRESH_JV_MEAL_SLOTS,
  freshJvMealMapsUrl,
} from "@/lib/fresh-jv-meals";
import { CHICAGO_TZ } from "@/lib/events-format";
import { getFreshJvMealSignups } from "@/lib/sheets/fresh-jv-meals";

// Availability is filtered against the current time and read from a live sheet,
// so this must not be frozen at build time. 60s keeps the table close to real
// without hitting the Sheets API on every request; the form is the source of
// truth, so a minute of lag only ever costs a "that night was just taken" email.
export const revalidate = 60;

export const metadata = {
  title:
    "Freshmen & JV Meals | McNeil Mavericks Football Booster Club",
  description:
    "Sign up to pick up the freshmen and JV game night meals from Bush's Chicken and bring them to McNeil. The Booster Club places and pays for the order.",
};

const CONTACT_EMAIL = "boosters@mcneilmavericks.org";

/** Prefilled form link with this date's checkbox already ticked. */
function claimUrl(optionText: string): string {
  const base = FRESH_JV_MEALS_FORM_URL.replace(/\/viewform.*$/, "/viewform");
  return `${base}?usp=pp_url&entry.${FRESH_JV_MEALS_DATE_ENTRY_ID}=${encodeURIComponent(optionText)}`;
}

export default async function FreshJvMealsPage() {
  const signups = await getFreshJvMealSignups();

  // A night stays listed until the dinner has ENDED, so someone checking their
  // phone at 7:45 on the day still sees the one they are driving to.
  // `new Date()` rather than `Date.now()`: react-hooks/purity rejects the
  // latter in a render, and app/events/page.tsx already set this precedent.
  const now = new Date().getTime();
  const upcoming = FRESH_JV_MEAL_SLOTS.filter(
    (s) => new Date(s.endsAt).getTime() > now,
  );

  const configured =
    !FRESH_JV_MEALS_FORM_URL.includes("__REPLACE_") &&
    !FRESH_JV_MEALS_DATE_ENTRY_ID.includes("__REPLACE_");

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
                Freshmen &amp; JV Meals
              </h1>
            </div>
            <div className="hidden md:block w-20 shrink-0" aria-hidden="true" />
          </div>
        </div>
      </section>

      <section className="container mx-auto px-4 py-10 md:py-12 max-w-3xl">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            On freshman and JV game nights the Booster Club feeds those
            players and coaching staffs. We need one volunteer per afternoon to
            collect the food and bring it to the school.
          </p>
          {/* ⚠️ This is the sentence that decides whether anyone signs up, so it
              is stated before the nights and repeated in the confirmation email.
              A volunteer who thinks they are buying dinner for a coaching staff
              either fronts the money at the counter or leaves without the food.
              It is also what makes this DIFFERENT from the other two meal
              programs, which get conflated constantly. */}
          <p className="font-semibold text-mavs-navy">
            The Booster Club places and pays for the order. You are not ordering
            the food, choosing it, or paying for it. Give your name at the
            counter and it will be waiting.
          </p>
          <p>
            Pick up from <strong>{FRESH_JV_MEAL_PICKUP_PLACE}</strong> and take
            it <strong>inside {FRESH_JV_MEAL_DROPOFF_PLACE}</strong>, where{" "}
            <strong>{FRESH_JV_MEAL_CONTACT}</strong> will meet you. About thirty
            minutes of your time.
          </p>
          {FRESH_JV_MEAL_PICKUP_TIME ? (
            <p>
              Pickup is at <strong>{FRESH_JV_MEAL_PICKUP_TIME}</strong> on the
              night you take
              {/* ⚠️ NO TRAILING PERIOD after a time. FRESH_JV_MEAL_*_TIME are
                  written "2:00 p.m." and already end in a full stop, so adding
                  one renders "2:30 p.m..". Latent until the constants stopped
                  being null on 2026-08-26. Same fix as timeSentence() in
                  fresh-jv-meals-automation.gs. */}
              {FRESH_JV_MEAL_DROPOFF_TIME ? (
                <>
                  , and drop-off is right after, by{" "}
                  <strong>{FRESH_JV_MEAL_DROPOFF_TIME}</strong>
                </>
              ) : (
                <>.</>
              )}
            </p>
          ) : (
            /* ⚠️ Do NOT replace this with a guessed time. A volunteer plans
               their afternoon around it, and a wrong number means cold food or a
               missed pickup. Set FRESH_JV_MEAL_PICKUP_TIME once Coach confirms
               it and this paragraph swaps itself out. */
            <p>
              <strong>We are still confirming the exact pickup time.</strong>{" "}
              Plan on mid afternoon. We will email you the exact time before your
              night, so you do not need to chase us for it.
            </p>
          )}
          {!FRESH_JV_MEAL_DROPOFF_CONFIRMED ? (
            <p className="text-base text-gray-700">
              We will confirm the exact drop-off spot with you the week of your
              night.
            </p>
          ) : null}
          {/* ⚠️ Lives OUTSIDE the DROPOFF_CONFIRMED block on purpose. It used to
              be the second sentence inside it, and flipping that flag to true on
              2026-08-26 would have silently taken this with it -- leaving a
              volunteer with no idea they get a phone number at all. Coach Hale's
              actual number stays out of the page; see lib/fresh-jv-meals.ts. */}
          <p className="text-base text-gray-700">
            {FRESH_JV_MEAL_CONTACT}&apos;s number goes out in your confirmation
            email, so you can text him when you arrive.
          </p>
          <p>
            Nights below are first come, first served. Note that{" "}
            <strong>September 23 is a Wednesday</strong> — that week plays a day
            early.
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
                        {/* 🚨 NEVER render a time off `startsAt` here. Those
                            timestamps are a PLACEHOLDER window while the real
                            pickup time is unknown, so formatting them would put
                            a confident, invented "3:00 PM" in front of a
                            volunteer. The clock time comes from
                            FRESH_JV_MEAL_PICKUP_TIME or it does not appear. */}
                        <p className="text-sm text-gray-600 mt-1">
                          {FRESH_JV_MEAL_PICKUP_TIME ?? "Time TBC"}
                        </p>
                      </div>

                      <div className="flex-1 min-w-0">
                        <p className="font-bold text-mavs-navy text-lg">
                          vs {slot.opponent}
                        </p>
                        <p className="text-sm text-gray-700 mt-1">
                          Freshman and JV both play this night.
                        </p>
                        <p className="text-sm text-gray-700 mt-2 flex items-start gap-1.5">
                          <MapPin size={15} className="mt-0.5 shrink-0" aria-hidden="true" />
                          <a
                            href={freshJvMealMapsUrl()}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="hover:text-mavs-navy hover:underline"
                          >
                            {FRESH_JV_MEAL_PICKUP_PLACE},{" "}
                            {FRESH_JV_MEAL_PICKUP_ADDRESS}
                          </a>
                        </p>
                        <p className="text-sm text-gray-700 mt-1 flex items-start gap-1.5">
                          <Utensils size={15} className="mt-0.5 shrink-0" aria-hidden="true" />
                          Order is already placed and paid for. Collect and
                          deliver.
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
              href={FRESH_JV_MEALS_FORM_URL}
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
            <strong>What do I actually do?</strong> Drive to{" "}
            {FRESH_JV_MEAL_PICKUP_PLACE}, give your name, and take the order{" "}
            <strong>inside {FRESH_JV_MEAL_DROPOFF_PLACE}</strong>.{" "}
            {FRESH_JV_MEAL_CONTACT} meets you there and takes it from you. You
            are not ordering, paying, or serving.
          </p>
          {/* Deliberately does not name a number. There is no headcount for this
              program (Jeremy 2026-08-26) and the point of the answer is that the
              volunteer never needs one. */}
          <p>
            <strong>How many meals is it?</strong> You do not need to know. The
            club places the order, so the count is already handled before you get
            there.
          </p>
          <p>
            <strong>What time?</strong>{" "}
            {FRESH_JV_MEAL_PICKUP_TIME ? (
              <>
                {FRESH_JV_MEAL_PICKUP_TIME} We will email you if that ever
                changes for a particular night.
              </>
            ) : (
              <>
                Still being confirmed — plan on mid afternoon. We email the exact
                time before your night rather than guessing at one here.
              </>
            )}
          </p>
          <p>
            <strong>Want to split the season with someone?</strong> Sign up for
            the nights you can take and say so in the notes. Several people each
            taking a couple of nights is exactly how this works best.
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
