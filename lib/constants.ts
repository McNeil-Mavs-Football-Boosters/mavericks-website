export const BOOSTER_FORM_URL =
  "https://docs.google.com/forms/d/e/1FAIpQLSfJXyssXItMv8EUU3FHkPqMo_9DGpReNlUq283NimBwa-rx1Q/viewform";

export const VOLUNTEER_FORM_URL =
  "https://docs.google.com/forms/d/e/1FAIpQLSfcpW_jAdJexrfSDcUlRZt78dv3S3omPysOR-RoOfY_1TWWkQ/viewform";

// "2026 Tunnel Volunteers" — a dedicated form for the tunnel crew, since that
// role needs the player's name/grade and an early-arrival acknowledgment the
// general volunteer-interest form doesn't collect. Verified live 2026-08-14.
export const TUNNEL_VOLUNTEER_FORM_URL =
  "https://docs.google.com/forms/d/e/1FAIpQLSe3e5uunfql2oDBI_XsbtU7l2XJ2lMvCCAmZmk27IAbx8LBBg/viewform";

export const DONATION_FORM_URL =
  "https://docs.google.com/forms/d/e/1FAIpQLSepjuuCP85fsBKgZU2uA4I-h9JWUkH3-ee9Juc8kC_ybrx5CA/viewform";

export const SPONSOR_FORM_URL =
  "https://docs.google.com/forms/d/e/1FAIpQLSe5iIQUJn_-JALXYJtLmWA3CQhEhCMreLY7vIgfllqppNnFJg/viewform";

export const DONATION_SHEET_ID = "1Dk-qdY0SiK1YlG9hPmEV7V__e1j2UoojJI3H6rYLmOI";

export const VENMO_HANDLE = "@McNeil-Football";

export const CLEAR_BAG_POLICY_URL =
  "https://www.roundrockisd.org/page/clear-bag-policy";

// ── Coaches meal pickup ──
// Created by MavericksWebsite/scripts/create-coach-meals-form.gs. That script
// logs all three of these values at the end of its run; paste them here.
//
// ⚠️ Until these are filled in, /boosters/coach-meals renders its error state
// rather than an empty table. That is deliberate: an all-open table on a page
// that cannot actually read signups would invite people to claim dates that
// are already covered.
export const COACH_MEALS_FORM_URL = "__REPLACE_WITH_PUBLISHED_FORM_URL__";
export const COACH_MEALS_SHEET_ID = "__REPLACE_WITH_SHEET_ID__";

// The `entry.NNNNNNNNN` parameter for the "Which date(s) can you cover?"
// checkbox. Prefill works by repeating this param once per checked option, and
// Google silently IGNORES a value it cannot match rather than erroring — so a
// wrong id here produces a link that opens the form with nothing checked and no
// visible symptom. The generator extracts it via toPrefilledUrl(); do not guess.
export const COACH_MEALS_DATE_ENTRY_ID = "__REPLACE_WITH_ENTRY_ID__";
