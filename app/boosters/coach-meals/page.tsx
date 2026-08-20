import Image from "next/image";
import { formatInTimeZone } from "date-fns-tz";
import { CalendarCheck, MapPin, Phone } from "lucide-react";

import {
  COACH_MEALS_DATE_ENTRY_ID,
  COACH_MEALS_FORM_URL,
} from "@/lib/constants";
import {
  COACH_MEAL_HEADCOUNT,
  COACH_MEAL_LOCATIONS,
  COACH_MEAL_SLOTS,
  COACH_MEAL_WINDOW,
  COACH_MEAL_PICKUP_TIME,
  COACH_MEAL_DROPOFF_TIME,
  COACH_MEAL_DROPOFF_PLACE,
  locationForSlot,
  mapsUrlForAddress,
} from "@/lib/coach-meals";
import { CHICAGO_TZ } from "@/lib/events-format";
import { getCoachMealSignups } from "@/lib/sheets/coach-meals";
import { getSponsorLogosByName } from "@/lib/queries/sponsors";
import { getSiteSettingsCore } from "@/lib/site-settings";
import { publicStorageUrl } from "@/lib/storage";

// Availability is filtered against the current time and read from a live sheet,
// so this must not be frozen at build time. 60s keeps the table close to real
// without hitting the Sheets API on every request; the form is the source of
// truth, so a minute of lag only ever costs a "that date was just taken" email.
export const revalidate = 60;

export const metadata = {
  title: "Coaches Meal Pickup | McNeil Mavericks Football Booster Club",
  description:
    "Sign up to pick up and deliver a donated lunch for the McNeil coaching staff on a game-week Sunday.",
};

const CONTACT_EMAIL = "boosters@mcneilmavericks.org";

/** Prefilled form link with this date's checkbox already ticked. */
function claimUrl(optionText: string): string {
  const base = COACH_MEALS_FORM_URL.replace(/\/viewform.*$/, "/viewform");
  return `${base}?usp=pp_url&entry.${COACH_MEALS_DATE_ENTRY_ID}=${encodeURIComponent(optionText)}`;
}

export default async function CoachMealsPage() {
  const { current_year } = await getSiteSettingsCore();

  const [signups, logos] = await Promise.all([
    getCoachMealSignups(),
    getSponsorLogosByName(
      Object.values(COACH_MEAL_LOCATIONS).map((l) => l.sponsorName),
      current_year,
    ),
  ]);

  // A slot stays listed until its serve window has ENDED, so someone checking
  // their phone at 12:45 on the day still sees the one they are driving to.
  // `new Date()` rather than `Date.now()`: react-hooks/purity rejects the
  // latter in a render, and app/events/page.tsx already set this precedent.
  const now = new Date().getTime();
  const upcoming = COACH_MEAL_SLOTS.filter(
    (s) => new Date(s.endsAt).getTime() > now,
  );

  const configured =
    !COACH_MEALS_FORM_URL.includes("__REPLACE_") &&
    !COACH_MEALS_DATE_ENTRY_ID.includes("__REPLACE_");

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
                Coaches Meal Pickup
              </h1>
            </div>
            <div className="hidden md:block w-20 shrink-0" aria-hidden="true" />
          </div>
        </div>
      </section>

      <section className="container mx-auto px-4 py-10 md:py-12 max-w-3xl">
        <div className="space-y-4 text-lg leading-relaxed text-gray-800">
          <p>
            Our coaching staff meets for lunch the Sunday before each varsity
            game. A local restaurant donates the meal for {COACH_MEAL_HEADCOUNT}{" "}
            coaches, and we just need a parent to pick it up at{" "}
            {COACH_MEAL_PICKUP_TIME} and drop it off at {COACH_MEAL_DROPOFF_TIME}{" "}
            in {COACH_MEAL_DROPOFF_PLACE}.
          </p>
          <p className="font-semibold text-mavs-navy">
            You are not buying the food. It is donated and already paid for. The
            only ask is the drive.
          </p>
          <p>
            Dates below are first come, first served. Pick one, or grab a few if
            you can. After you sign up we will email you the restaurant address,
            who to ask for when you get there, and a reminder before your date.
          </p>
        </div>
      </section>

      <section className="container mx-auto px-4 pb-4 md:pb-6">
        <div className="max-w-4xl mx-auto">
          {!signups.ok ? (
            /* ⚠️ Never render availability we could not verify. Showing every
               date as open would invite people to claim dates that are already
               covered — the exact problem this page exists to solve. */
            <div className="border-2 border-mavs-navy/20 rounded-lg p-6 md:p-8 text-center bg-gray-50">
              <h2 className="text-2xl font-bold text-mavs-navy">
                We can&apos;t load the current signups right now
              </h2>
              <p className="text-gray-700 mt-3 max-w-xl mx-auto">
                Rather than show you dates that might already be taken, we are
                showing nothing at all. Please check back shortly, or email{" "}
                <a
                  href={`mailto:${CONTACT_EMAIL}`}
                  className="font-bold text-mavs-navy underline underline-offset-2"
                >
                  {CONTACT_EMAIL}
                </a>{" "}
                and we will get you on a date.
              </p>
            </div>
          ) : upcoming.length === 0 ? (
            <div className="border-2 border-mavs-navy/20 rounded-lg p-6 md:p-8 text-center bg-gray-50">
              <h2 className="text-2xl font-bold text-mavs-navy">
                That&apos;s a wrap on this season
              </h2>
              <p className="text-gray-700 mt-3">
                Every coaches meal date has passed. Thank you to everyone who
                drove one over.
              </p>
            </div>
          ) : (
            <ul className="space-y-4">
              {upcoming.map((slot) => {
                const loc = locationForSlot(slot);
                const claim = signups.claimsByDate.get(slot.date);
                const sponsor = logos.get(loc.sponsorName);
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
                        <p className="font-black uppercase text-mavs-navy text-lg leading-tight">
                          {formatInTimeZone(start, CHICAGO_TZ, "EEEE")}
                        </p>
                        <p className="font-black uppercase text-mavs-navy text-2xl leading-tight">
                          {formatInTimeZone(start, CHICAGO_TZ, "MMMM d")}
                        </p>
                        <p className="text-sm text-gray-600 mt-1">
                          {COACH_MEAL_WINDOW}
                        </p>
                      </div>

                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-3">
                          {sponsor?.logo_url ? (
                            /* Plain <img>, matching every other sponsor logo on
                               this site: they are served straight from Supabase
                               so they never touch the Vercel image optimizer,
                               whose cache-write quota this project has already
                               had to go fix once. */
                            /* eslint-disable-next-line @next/next/no-img-element */
                            <img
                              src={publicStorageUrl(
                                sponsor.logo_url,
                                "sponsor-logos",
                              )}
                              alt=""
                              className="h-8 w-auto max-w-[110px] object-contain shrink-0"
                            />
                          ) : null}
                          <p className="font-bold text-mavs-navy text-lg truncate">
                            {sponsor?.website_url ? (
                              <a
                                href={sponsor.website_url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="hover:underline"
                              >
                                {loc.label}
                              </a>
                            ) : (
                              loc.label
                            )}
                          </p>
                        </div>
                        <p className="text-sm text-gray-700 mt-2 flex items-start gap-1.5">
                          <MapPin size={15} className="mt-0.5 shrink-0" aria-hidden="true" />
                          <a
                            href={mapsUrlForAddress(loc.address)}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="hover:text-mavs-navy hover:underline"
                          >
                            {loc.address}
                          </a>
                        </p>
                        <p className="text-sm text-gray-700 mt-1 flex items-center gap-1.5">
                          <Phone size={15} className="shrink-0" aria-hidden="true" />
                          <a
                            href={`tel:${loc.phone.replace(/[^0-9]/g, "")}`}
                            className="hover:text-mavs-navy hover:underline"
                          >
                            {loc.phone}
                          </a>
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
                            Claim this date
                          </a>
                        ) : (
                          <a
                            href={`mailto:${CONTACT_EMAIL}?subject=Coaches%20meal%20pickup`}
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
            Want several dates at once?{" "}
            <a
              href={COACH_MEALS_FORM_URL}
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
            <strong>Something come up?</strong> Email{" "}
            <a
              href={`mailto:${CONTACT_EMAIL}`}
              className="font-bold text-mavs-navy underline underline-offset-2"
            >
              {CONTACT_EMAIL}
            </a>{" "}
            and we will reopen your date. As much notice as you can give is
            appreciated, but tell us either way. A date nobody knows is uncovered
            is much worse than one we can hand to someone else.
          </p>
          <p>
            Didn&apos;t get a confirmation email within a few minutes? Check your
            spam, then email us. It usually means a typo in the address, and
            without it you will not get your reminder either.
          </p>
        </div>
      </section>
    </>
  );
}
