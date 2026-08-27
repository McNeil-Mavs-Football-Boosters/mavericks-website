/**
 * Freshman and JV game night meals for the 2026 season.
 *
 * On each freshman/JV game night the Booster Club feeds those teams' PLAYERS AND
 * coaching staffs. **The Booster Club places and pays for the order in advance.**
 * A parent volunteer only collects it from Bush's Chicken and brings it to the
 * school, where Coach Hale meets them. No ordering, no menu decisions, no money.
 * They are a courier.
 *
 * ⚠️ WIDENED 2026-08-26, AND IT CHANGES WHAT THIS IS. Built first as a
 * coaches-only pickup; Jeremy then included the players. So this **IS** the
 * freshman/JV slice of game-day meals, out of the booster budget -- not a
 * separate programme running alongside it. The original copy said "this is NOT
 * the game-day meals program", which became flatly wrong the moment players were
 * included, and it sat on the live form for a few hours before being removed.
 * **Do not reintroduce that line anywhere.**
 *
 * ⚠️ NO HEADCOUNT, DELIBERATELY. Jeremy 2026-08-26: "we don't have a headcount.
 * you don't need to bother with that." No surface states or implies a number of
 * meals, and none should. Do not infer one from the rosters either -- varsity is
 * 45 and extrapolating a sub-varsity figure would put an invented number in
 * front of a volunteer deciding whether their car is big enough.
 *
 * ⚠️ THREE MEAL PROGRAMMES GET CONFLATED. Keep them straight:
 *   - Coaches Sunday Lunch  = 12 coaches, Sundays, a restaurant donates,
 *                             /boosters/coach-meals. A different thing.
 *   - Varsity team dinner   = the night BEFORE a varsity game, host-funded out
 *                             of a family's own pocket, /boosters/team-dinners.
 *                             A different thing.
 *   - THIS                  = freshman + JV players and coaching staffs on their
 *                             own game nights, club orders and pays.
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
 * ⚠️ CONFIRMED 2026-08-26, AND IT IS NOT THE HORSESHOE. This used to hedge on
 * Jeremy's guess: "probably in the horseshoe parking lot and coach hale will
 * meet them there." Debbie Reeves then ran the first real delivery on Sunday 23
 * August, unloaded at a horseshoe outdoor table because that is what we told
 * her, found nobody waiting, and had to carry the order "to a door around the
 * corner and inside". Her recommendation, adopted verbatim by Jeremy: delivery
 * is made inside the doors where players are dropped off, not the horseshoe.
 *
 * Keep in step with DROPOFF_PLACE in
 * `MavericksWebsite/scripts/fresh-jv-meals-automation.gs`.
 */
export const FRESH_JV_MEAL_DROPOFF_PLACE =
  "the Player Drop-off Doors on the east side of the building";
export const FRESH_JV_MEAL_DROPOFF_CONFIRMED = true;

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
