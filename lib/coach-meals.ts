/**
 * Coaches meal pickup slots for the 2026 season.
 *
 * Twelve coaches meet for lunch the Sunday before each varsity game (no
 * scrimmages). A restaurant donates the food; a parent volunteer picks it up
 * and delivers it between 12:30 and 1:00 p.m. Ten Sundays, four pickup
 * locations.
 *
 * ── THIS FILE IS THE SINGLE SOURCE FOR THE SLOT LIST ──
 * Three things read it and they must not drift:
 *   1. /boosters/coach-meals renders the availability table from it.
 *   2. The prefill links on that page build `entry.<id>=<optionText>` from it.
 *   3. `MavericksWebsite/scripts/create-coach-meals-form.gs` builds the Google
 *      Form's checkbox options from the SAME strings.
 *
 * ⚠️ `optionText` MUST match the live form's checkbox option byte-for-byte.
 * Google silently IGNORES a prefill value it cannot match rather than erroring,
 * so one character of drift produces a link that opens the form with nothing
 * checked and no visible symptom. This bit the sponsor form already. If you
 * edit an optionText here, regenerate or hand-edit the form to match, then
 * re-run the prefill verification.
 *
 * ⚠️ ASCII ONLY in `optionText` — straight apostrophes, plain hyphens, no em
 * dashes or curly quotes. Not a style preference: these strings are round-
 * tripped through a URL query parameter and compared byte-for-byte, and a
 * smart-quote substitution somewhere in that chain is a silent break.
 *
 * ⚠️ NO COMMAS in `optionText`, ever. Google Sheets joins multiple checkbox
 * selections into ONE cell separated by ", " - so an option containing a comma
 * is unsplittable and silently corrupts parsing. The strings deliberately read
 * "August 23 - Rudy's BBQ" rather than "Sunday, August 23 - ...". The page adds
 * the weekday back for display; the stored value stays parseable.
 *
 * All ten dates are CDT (-05:00). DST ends Nov 1 2026, after the last slot, so
 * unlike the Q2 concession shifts there are no mixed offsets here.
 */

export const COACH_MEAL_HEADCOUNT = 12;
export const COACH_MEAL_WINDOW = "12:30 to 1:00 p.m.";

export interface CoachMealLocation {
  /** Must match `sponsors.name` exactly so the logo lookup resolves. */
  sponsorName: string;
  /** What the page shows. */
  label: string;
  address: string;
  phone: string;
}

/**
 * Four pickup locations.
 *
 * ⚠️ RUDY'S ADDRESS WAS WRONG IN THE SOURCE SPREADSHEET and is now corrected.
 * The sheet said "2400 Round Rock Ave"; Jeremy confirmed 2026-08-18 the real
 * pickup is "2400 N Interstate Hwy 35" - same street number, wrong street.
 * That also reconciles it with the form's "(Old Settlers and I-35)" label,
 * which is what surfaced the discrepancy in the first place. Do not "restore"
 * the Round Rock Ave address from the spreadsheet; the spreadsheet is the one
 * that is wrong.
 *
 * Tony C's and The League genuinely share an address - they are next door to
 * each other, both TC4 & Co. That is confirmed, not a data-entry error.
 */
export const COACH_MEAL_LOCATIONS = {
  rudys: {
    sponsorName: "Rudy's BBQ",
    label: "Rudy's BBQ (Old Settlers and I-35)",
    address: "2400 N Interstate Hwy 35, Round Rock, TX 78681",
    phone: "512-244-2936",
  },
  tonycs: {
    sponsorName: "Tony C's Coal Fired Pizza",
    label: "Tony C's (Avery and Parmer)",
    address: "10526 W Parmer Ln, Austin, TX 78717",
    phone: "512-255-9463",
  },
  league: {
    sponsorName: "The League Kitchen & Tavern",
    label: 'The League (Avery and Parmer)',
    address: "10526 W Parmer Ln, Austin, TX 78717",
    phone: "512-366-5627",
  },
  mightyfine: {
    sponsorName: "Mighty Fine Burgers",
    label: 'Mighty Fine (Mopac and Braker)',
    address: "10515 N Mopac Expy, Austin, TX 78759",
    phone: "512-524-2400",
  },
} as const satisfies Record<string, CoachMealLocation>;

export type CoachMealLocationKey = keyof typeof COACH_MEAL_LOCATIONS;

export interface CoachMealSlot {
  /** Chicago-local calendar date, and the stable key used everywhere. */
  date: string;
  /** Serve window start, explicit -05:00 offset. */
  startsAt: string;
  endsAt: string;
  locationKey: CoachMealLocationKey;
  /** The Google Form checkbox option. See the byte-for-byte warning above. */
  optionText: string;
}

export const COACH_MEAL_SLOTS: readonly CoachMealSlot[] = [
  { date: "2026-08-23", startsAt: "2026-08-23T12:30:00-05:00", endsAt: "2026-08-23T13:00:00-05:00", locationKey: "rudys",      optionText: "August 23 - Rudy's BBQ (Old Settlers and I-35)" },
  { date: "2026-08-30", startsAt: "2026-08-30T12:30:00-05:00", endsAt: "2026-08-30T13:00:00-05:00", locationKey: "tonycs",     optionText: "August 30 - Tony C's (Avery and Parmer)" },
  { date: "2026-09-06", startsAt: "2026-09-06T12:30:00-05:00", endsAt: "2026-09-06T13:00:00-05:00", locationKey: "league",     optionText: 'September 6 - The League (Avery and Parmer)' },
  { date: "2026-09-13", startsAt: "2026-09-13T12:30:00-05:00", endsAt: "2026-09-13T13:00:00-05:00", locationKey: "rudys",      optionText: "September 13 - Rudy's BBQ (Old Settlers and I-35)" },
  { date: "2026-09-20", startsAt: "2026-09-20T12:30:00-05:00", endsAt: "2026-09-20T13:00:00-05:00", locationKey: "mightyfine", optionText: 'September 20 - Mighty Fine (Mopac and Braker)' },
  { date: "2026-09-27", startsAt: "2026-09-27T12:30:00-05:00", endsAt: "2026-09-27T13:00:00-05:00", locationKey: "tonycs",     optionText: "September 27 - Tony C's (Avery and Parmer)" },
  { date: "2026-10-04", startsAt: "2026-10-04T12:30:00-05:00", endsAt: "2026-10-04T13:00:00-05:00", locationKey: "rudys",      optionText: "October 4 - Rudy's BBQ (Old Settlers and I-35)" },
  { date: "2026-10-11", startsAt: "2026-10-11T12:30:00-05:00", endsAt: "2026-10-11T13:00:00-05:00", locationKey: "league",     optionText: 'October 11 - The League (Avery and Parmer)' },
  { date: "2026-10-18", startsAt: "2026-10-18T12:30:00-05:00", endsAt: "2026-10-18T13:00:00-05:00", locationKey: "mightyfine", optionText: 'October 18 - Mighty Fine (Mopac and Braker)' },
  { date: "2026-10-25", startsAt: "2026-10-25T12:30:00-05:00", endsAt: "2026-10-25T13:00:00-05:00", locationKey: "tonycs",     optionText: "October 25 - Tony C's (Avery and Parmer)" },
];

export function locationForSlot(slot: CoachMealSlot): CoachMealLocation {
  return COACH_MEAL_LOCATIONS[slot.locationKey];
}

/**
 * Google Maps link for a pickup address.
 *
 * Uses the documented stable `search/?api=1&query=` form, the same one
 * migration 052 used for stadium addresses - never a `maps.app.goo.gl` short
 * link, which is opaque to anyone reviewing it and depends on a second service
 * staying up.
 *
 * Note this is deliberately NOT the `venues` table's rule of "only a pin a
 * human opened." That rule exists because a SCHOOL's street address is not its
 * stadium - proven eight times over. A restaurant's street address is the
 * restaurant, so an address search is the right answer here.
 */
export function mapsUrlForAddress(address: string): string {
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`;
}
