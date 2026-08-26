/**
 * Freshman and JV coaches meals for the 2026 season.
 *
 * On each freshman/JV game night the Booster Club feeds those teams' coaching
 * staffs. **The Booster Club places the order in advance.** A parent volunteer
 * only collects it from Bush's Chicken and brings it to the school, where Coach
 * Hale meets them. No ordering, no headcount, no menu decisions.
 *
 * That makes this the SIMPLEST of the three meal programs. Do not copy the
 * coach-meals or team-dinners framing that asks a volunteer to source or provide
 * food -- here they are a courier.
 *
 * ⚠️ THREE PROGRAMS GET CONFLATED. Keep them straight:
 *   - Game-day meals        = the players, all three levels, parents pay in,
 *                             booster budget carries it. Not this.
 *   - Coaches Sunday Lunch  = 12 coaches, Sundays, a restaurant donates,
 *                             /boosters/coach-meals. Not this.
 *   - THIS                  = freshman + JV coaching staffs on their game
 *                             nights, club orders, volunteer collects.
 *
 * ── THIS FILE IS THE SINGLE SOURCE FOR THE SLOT LIST ──
 * Three things read it and they must not drift:
 *   1. /boosters/fresh-jv-meals renders the availability table from it.
 *   2. The prefill links on that page build `entry.<id>=<optionText>` from it.
 *   3. `scripts/create-fresh-jv-meals-form.gs` builds the form's checkbox
 *      options from the SAME strings, and `fresh-jv-meals-automation.gs`
 *      matches sheet cells against them.
 * Run `scripts/check-fresh-jv-meal-options.py` after any edit.
 *
 * ⚠️ `optionText` MUST match the live form byte-for-byte. Google silently
 * IGNORES a prefill value it cannot match rather than erroring, so one character
 * of drift opens the form with nothing checked and no visible symptom.
 *
 * ⚠️ ASCII ONLY, and NO COMMAS. Sheets joins multiple checkbox selections into
 * one cell separated by ", ", so a comma inside an option makes the cell
 * unsplittable. That is why these read "August 27 - Austin Bowie" and not
 * "Thursday, August 27 - ...". The page adds the weekday back for display.
 *
 * ⚠️ NOT EVERY NIGHT IS A THURSDAY. The Lake Travis week plays WEDNESDAY
 * SEPT 23. Do not regularise it, and do not name this program "Thursday meals"
 * anywhere a volunteer can read it.
 *
 * All ten dates are CDT (-05:00). DST ends Nov 1 2026, after the last slot.
 */

/** Bush's Chicken. Always the same place -- Jeremy 2026-08-25. */
export const FRESH_JV_MEAL_PICKUP_PLACE = "Bush's Chicken - North Austin";
export const FRESH_JV_MEAL_PICKUP_ADDRESS =
  "12336 Ranch to Market Rd 620, Austin, TX 78750";

/**
 * 🚨 NOT YET KNOWN. Jeremy 2026-08-25: "I don't have all of the information yet
 * like pickup time but I assume midafternoon."
 *
 * **Leave this null until he confirms it. Do not write in "midafternoon" or a
 * guessed clock time.** A volunteer plans their afternoon around this number and
 * a wrong one means cold food or a missed pickup. While it is null every surface
 * says the time is confirmed by email, which is true and safe.
 *
 * Setting it here updates the page and the emails. The live Google Form's
 * description and help text must ALSO be hand-edited -- the generator only runs
 * at form creation. Same as the coach-meals 12:30/1:00 change.
 */
export const FRESH_JV_MEAL_PICKUP_TIME: string | null = null;

/**
 * ⚠️ UNCONFIRMED. Jeremy: "i don't know where they drop the food off but
 * probably in the horseshoe parking lot and coach hale will meet them there."
 * Stated as the likely spot and confirmed by email, never as fact.
 */
export const FRESH_JV_MEAL_DROPOFF_PLACE = "the Horseshoe lot at McNeil";
export const FRESH_JV_MEAL_DROPOFF_CONFIRMED = false;

/** Who meets the volunteer at the school. */
export const FRESH_JV_MEAL_CONTACT = "Coach Hale";

export interface FreshJvMealSlot {
  /** Chicago-local calendar date, and the stable key everywhere. */
  date: string;
  /** Explicit -05:00 offset. Per-slot so a single week can be moved. */
  startsAt: string;
  endsAt: string;
  /** Opponent both squads play that night. Display only. */
  opponent: string;
  /** The Google Form checkbox option. See the byte-for-byte warning above. */
  optionText: string;
}

/**
 * The ten freshman/JV game nights, from the schedule in the database
 * (2026-08-25). These are the SAME ten calendar dates as the varsity team
 * dinners, because the varsity dinner is the night before the varsity game and
 * freshman/JV play that night -- a coincidence of the schedule, not a link
 * between the programs. Do not derive one list from the other.
 *
 * `startsAt` is a placeholder window while the pickup time is unknown; the page
 * and the emails key off FRESH_JV_MEAL_PICKUP_TIME, not off this.
 */
export const FRESH_JV_MEAL_SLOTS: readonly FreshJvMealSlot[] = [
  { date: "2026-08-27", startsAt: "2026-08-27T15:00:00-05:00", endsAt: "2026-08-27T17:00:00-05:00", opponent: "Austin Bowie", optionText: "August 27 - Austin Bowie" },
  { date: "2026-09-03", startsAt: "2026-09-03T15:00:00-05:00", endsAt: "2026-09-03T17:00:00-05:00", opponent: "Lake Belton",  optionText: "September 3 - Lake Belton" },
  { date: "2026-09-10", startsAt: "2026-09-10T15:00:00-05:00", endsAt: "2026-09-10T17:00:00-05:00", opponent: "Rouse",        optionText: "September 10 - Rouse" },
  { date: "2026-09-17", startsAt: "2026-09-17T15:00:00-05:00", endsAt: "2026-09-17T17:00:00-05:00", opponent: "Vista Ridge",  optionText: "September 17 - Vista Ridge" },
  // WEDNESDAY. The Lake Travis week plays a day early. This is not a typo.
  { date: "2026-09-23", startsAt: "2026-09-23T15:00:00-05:00", endsAt: "2026-09-23T17:00:00-05:00", opponent: "Lake Travis",  optionText: "September 23 - Lake Travis" },
  { date: "2026-10-01", startsAt: "2026-10-01T15:00:00-05:00", endsAt: "2026-10-01T17:00:00-05:00", opponent: "Cedar Ridge",  optionText: "October 1 - Cedar Ridge" },
  { date: "2026-10-08", startsAt: "2026-10-08T15:00:00-05:00", endsAt: "2026-10-08T17:00:00-05:00", opponent: "Stony Point",  optionText: "October 8 - Stony Point" },
  { date: "2026-10-15", startsAt: "2026-10-15T15:00:00-05:00", endsAt: "2026-10-15T17:00:00-05:00", opponent: "Westlake",     optionText: "October 15 - Westlake" },
  { date: "2026-10-22", startsAt: "2026-10-22T15:00:00-05:00", endsAt: "2026-10-22T17:00:00-05:00", opponent: "Round Rock",   optionText: "October 22 - Round Rock" },
  { date: "2026-10-29", startsAt: "2026-10-29T15:00:00-05:00", endsAt: "2026-10-29T17:00:00-05:00", opponent: "Westwood",     optionText: "October 29 - Westwood" },
];

/**
 * Google Maps link for the pickup.
 *
 * Built from the ADDRESS with the documented stable `search/?api=1&query=` form,
 * matching lib/coach-meals.ts and lib/team-dinners.ts.
 *
 * ⚠️ Jeremy supplied this as a `maps.app.goo.gl` short link. Short links are
 * never stored here: they are opaque to review, they depend on a second Google
 * service staying up, and they cannot be checked by reading the code. The short
 * link was resolved once to the address above and the address is what is kept.
 */
export function freshJvMealMapsUrl(): string {
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(
    `${FRESH_JV_MEAL_PICKUP_PLACE} ${FRESH_JV_MEAL_PICKUP_ADDRESS}`,
  )}`;
}
