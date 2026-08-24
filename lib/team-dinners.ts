/**
 * Varsity team dinner slots for the 2026 season.
 *
 * The varsity squad eats together the night before each varsity game. Coach
 * moved these ON CAMPUS for 2026 (booster meeting 2026-08-17): the boys are
 * already at school, they stay to support the freshman/JV game, and some do not
 * have rides. Historically senior parents hosted at their homes on a rotation.
 * A volunteer signs up to PROVIDE THE FOOD, serve it, and clean up after.
 *
 * ⚠️ THIS IS NOT A BOOSTER-CLUB-FUNDED MEAL. Two different things get conflated
 * constantly and the page says so out loud:
 *   - "Team meals" / game-day meals   = parents pay in, the club runs them.
 *   - "Varsity team dinner" (THIS)    = the host covers it. Not a club expense.
 * A volunteer who signs up thinking the club reimburses them will find out at
 * the checkout, which is the worst possible moment.
 *
 * ── THIS FILE IS THE SINGLE SOURCE FOR THE SLOT LIST ──
 * Three things read it and they must not drift:
 *   1. /boosters/team-dinners renders the availability table from it.
 *   2. The prefill links on that page build `entry.<id>=<optionText>` from it.
 *   3. `MavericksWebsite/scripts/create-team-dinners-form.gs` builds the Google
 *      Form's checkbox options from the SAME strings, and
 *      `team-dinners-automation.gs` matches sheet cells against them.
 * Run `MavericksWebsite/scripts/check-team-dinner-options.py` after any edit.
 *
 * ⚠️ `optionText` MUST match the live form's checkbox option byte-for-byte.
 * Google silently IGNORES a prefill value it cannot match rather than erroring,
 * so one character of drift produces a link that opens the form with nothing
 * checked and no visible symptom. Same trap the sponsor and coach-meal forms
 * both hit.
 *
 * ⚠️ ASCII ONLY in `optionText` — straight apostrophes, plain hyphens, no em
 * dashes or curly quotes. These strings round-trip through a URL query
 * parameter and are compared byte-for-byte.
 *
 * ⚠️ NO COMMAS in `optionText`, ever. Google Sheets joins multiple checkbox
 * selections into ONE cell separated by ", ", so an option containing a comma
 * is unsplittable. That is why these read "August 27 - before Austin Bowie"
 * rather than "Thursday, August 27 - ...". The page adds the weekday back for
 * display; the stored value stays parseable.
 *
 * ⚠️ NO OCCASION MARKERS IN `optionText`. Senior Night moved once already
 * (Sept 4 -> Oct 9, migration 151) and Homecoming could. Option text is frozen
 * into the live form the moment it is created and cannot be corrected without
 * breaking every prefill link and every stored response. Occasions live in
 * `occasion` below, which only ever renders on the page and can be edited
 * freely.
 *
 * ── ⚠️ THE DATES ARE DERIVED FROM THE GAME SCHEDULE AND DO NOT TRACK IT ──
 * Each dinner is the calendar day before a varsity game in
 * `db/migrations/057_seed_2026_schedule.sql` (times later amended by 155; no
 * varsity DATE has moved). NOT every dinner is a Thursday: the Lake Travis game
 * is on THURSDAY Sept 24, so that dinner is WEDNESDAY Sept 23. Do not "fix"
 * it into the Thursday pattern. If a varsity game is ever rescheduled, this
 * list does not notice — the option text is already frozen in the form, so the
 * fix is a page/email note, not an edit here.
 *
 * All ten dates are CDT (-05:00). DST ends Nov 1 2026, after the last slot.
 */

/**
 * 45 varsity players plus ~5 coaches and staff. Jeremy, 2026-08-24.
 *
 * The breakdown is a separate constant so the page never states a second number
 * that can fall out of step with the total — the whole point of the sentence is
 * that a host can sanity-check the 50 against something.
 *
 * Mirrored as `HEADCOUNT` in BOTH `scripts/create-team-dinners-form.gs` (which
 * bakes it into the form description) and `scripts/team-dinners-automation.gs`
 * (which puts it in every confirmation and reminder). check-team-dinner-
 * options.py compares all three.
 */
export const TEAM_DINNER_HEADCOUNT = 50;
export const TEAM_DINNER_BREAKDOWN = "45 players plus coaches and staff";

/**
 * The default start time. Individual weeks can and will move — Jeremy's read
 * 2026-08-24 is that the team leaves the JV game around halftime and eats, and
 * that is still to be confirmed with Coach. So the PER-SLOT `startsAt` is what
 * the page and the emails actually show; this constant is only for the
 * intro copy, which is hedged to match.
 *
 * Keep in step with the `time` field on each slot in
 * `MavericksWebsite/scripts/team-dinners-automation.gs` — that is what the
 * confirmation and reminder emails say. The drift checker compares them.
 */
export const TEAM_DINNER_DEFAULT_TIME = "7:00 p.m.";

export const TEAM_DINNER_PLACE = "McNeil High School";
export const TEAM_DINNER_ADDRESS = "5720 McNeil Drive, Austin, TX 78729";
/**
 * Coach has rooms lined up if the cafeteria is taken (booster meeting
 * 2026-08-17), so the ROOM is genuinely not known this far out. Saying
 * "cafeteria" flatly would send someone with six foil trays to a locked door.
 */
export const TEAM_DINNER_ROOM_NOTE =
  "Usually the cafeteria. Coach has other rooms lined up if it is booked, and we confirm the room by email the week of your date.";

export interface TeamDinnerSlot {
  /** Chicago-local calendar date of the DINNER, and the stable key everywhere. */
  date: string;
  /** Explicit -05:00 offset. Per-slot so a single week can be moved. */
  startsAt: string;
  endsAt: string;
  /** Varsity opponent the following day. Display only. */
  opponent: string;
  /** Chicago-local calendar date of that game. Display only. */
  gameDate: string;
  /** 'Senior Night' | 'Homecoming' | null. Display only — never in optionText. */
  occasion: string | null;
  /** The Google Form checkbox option. See the byte-for-byte warning above. */
  optionText: string;
}

export const TEAM_DINNER_SLOTS: readonly TeamDinnerSlot[] = [
  { date: "2026-08-27", startsAt: "2026-08-27T19:00:00-05:00", endsAt: "2026-08-27T20:30:00-05:00", opponent: "Austin Bowie",  gameDate: "2026-08-28", occasion: null,           optionText: "August 27 - before Austin Bowie" },
  { date: "2026-09-03", startsAt: "2026-09-03T19:00:00-05:00", endsAt: "2026-09-03T20:30:00-05:00", opponent: "Lake Belton",   gameDate: "2026-09-04", occasion: null,           optionText: "September 3 - before Lake Belton" },
  { date: "2026-09-10", startsAt: "2026-09-10T19:00:00-05:00", endsAt: "2026-09-10T20:30:00-05:00", opponent: "Rouse",         gameDate: "2026-09-11", occasion: null,           optionText: "September 10 - before Rouse" },
  { date: "2026-09-17", startsAt: "2026-09-17T19:00:00-05:00", endsAt: "2026-09-17T20:30:00-05:00", opponent: "Vista Ridge",   gameDate: "2026-09-18", occasion: null,           optionText: "September 17 - before Vista Ridge" },
  // WEDNESDAY. The Lake Travis game is a Thursday. This is not a typo.
  { date: "2026-09-23", startsAt: "2026-09-23T19:00:00-05:00", endsAt: "2026-09-23T20:30:00-05:00", opponent: "Lake Travis",   gameDate: "2026-09-24", occasion: null,           optionText: "September 23 - before Lake Travis" },
  { date: "2026-10-01", startsAt: "2026-10-01T19:00:00-05:00", endsAt: "2026-10-01T20:30:00-05:00", opponent: "Cedar Ridge",   gameDate: "2026-10-02", occasion: null,           optionText: "October 1 - before Cedar Ridge" },
  { date: "2026-10-08", startsAt: "2026-10-08T19:00:00-05:00", endsAt: "2026-10-08T20:30:00-05:00", opponent: "Stony Point",   gameDate: "2026-10-09", occasion: "Senior Night", optionText: "October 8 - before Stony Point" },
  { date: "2026-10-15", startsAt: "2026-10-15T19:00:00-05:00", endsAt: "2026-10-15T20:30:00-05:00", opponent: "Westlake",      gameDate: "2026-10-16", occasion: null,           optionText: "October 15 - before Westlake" },
  { date: "2026-10-22", startsAt: "2026-10-22T19:00:00-05:00", endsAt: "2026-10-22T20:30:00-05:00", opponent: "Round Rock",    gameDate: "2026-10-23", occasion: "Homecoming",   optionText: "October 22 - before Round Rock" },
  { date: "2026-10-29", startsAt: "2026-10-29T19:00:00-05:00", endsAt: "2026-10-29T20:30:00-05:00", opponent: "Westwood",      gameDate: "2026-10-30", occasion: null,           optionText: "October 29 - before Westwood" },
];

/**
 * Google Maps link for the campus.
 *
 * Documented stable `search/?api=1&query=` form, matching lib/coach-meals.ts —
 * never a `maps.app.goo.gl` short link, which is opaque to review and depends
 * on a second service staying up.
 *
 * ⚠️ This deliberately points at the CAMPUS address, not at Maverick Stadium.
 * The `venues` table keeps them as two rows with the same street address for
 * exactly this reason (migration 135): the dinner is inside the building, the
 * game is at the field, and a parent carrying trays wants the school entrance.
 */
export function teamDinnerMapsUrl(): string {
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(
    TEAM_DINNER_ADDRESS,
  )}`;
}
