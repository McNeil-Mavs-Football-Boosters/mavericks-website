import "server-only";

import { cache } from "react";
import { google } from "googleapis";

import { FRESH_JV_MEALS_SHEET_ID } from "@/lib/constants";
import { FRESH_JV_MEAL_SLOTS } from "@/lib/fresh-jv-meals";
import { formatShortName } from "@/lib/sheets/boosters";

/**
 * Read-only access to the Freshman & JV Coaches Meals Form-responses sheet.
 *
 * Structurally identical to `lib/sheets/team-dinners.ts` and `coach-meals.ts`
 * and deliberately kept that way — same service-account JWT
 * (`mcneil-site-reader@…`, sheet shared at Viewer), same first-wins rule, same
 * discriminated-union failure mode. Sheet id is a code constant rather than env
 * because it is not secret.
 *
 * ── FIRST-WINS IS THE WHOLE MECHANISM ──
 * A Google Form is append-only: every submission is a new row and nothing can
 * ever overwrite anything. So "first one to submit gets the date" is not a
 * locking problem, it is a resolution rule applied at read time — for each
 * date, the earliest non-cancelled row that checked it owns it. Later rows for
 * that date are losers and are reported as such so the automation can email
 * them.
 *
 * ── ⚠️ WHY THIS READER DOES NOT RETURN [] ON FAILURE ──
 * The other sheet readers here log and return an empty array and the page shows
 * an empty state. Doing that HERE would be actively harmful: no claims parsed
 * renders every night as OPEN, and the page would confidently send several
 * people to Bush's Chicken for the same pre-placed order.
 *
 * So this returns a discriminated union and the caller MUST handle `ok: false`
 * by showing an error state instead of availability. A page that admits it
 * cannot load is recoverable. A page that lies about availability is not.
 */

const SHEET_TAB = "Form Responses 1";
/**
 * A:Z, deliberately wider than the columns actually used.
 *
 * team-dinners pinned A:J to its exact column count and donations.ts pinned A:L
 * to its own — and A:L was found on 2026-08-25 to be ONE form question away from
 * silently emptying the donor wall, because a new question shoves the manually
 * added admin columns right. Every column here is resolved BY HEADER NAME, so
 * reading past the end costs nothing and removes that landmine entirely.
 * Do not narrow this to fit the current sheet.
 */
const READ_RANGE = `'${SHEET_TAB}'!A:Z`;
const SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly";

/**
 * ⚠️ Must match the sheet's header row EXACTLY. Columns A-F are the Google
 * Form's question titles, so editing a question in the form rewrites the header
 * here and breaks the match. G-J are added by the generator script.
 *
 * Matching is exact, never fuzzy — same rule as `donations.ts`, where a
 * near-match on the anonymity column could have outed a donor. If the page
 * starts showing its error state, dump row 1 and diff it against this first.
 */
const COL_HEADERS = {
  timestamp: "Timestamp",
  dates: "Which night(s) can you cover?",
  name: "Your name",
  email: "Email",
  phone: "Phone",
  cancelled: "Cancelled",
} as const;

/** One resolved date claim, redacted for public display. */
export interface FreshJvMealClaim {
  /** Slot date, `YYYY-MM-DD`. */
  date: string;
  /** "Sarah M." — first name plus last initial, never the full surname. */
  displayName: string;
  claimedAt: Date | null;
}

export type FreshJvMealSignups =
  | { ok: true; claimsByDate: Map<string, FreshJvMealClaim> }
  | { ok: false; reason: string };

function buildAuth() {
  const email = process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL;
  const rawKey = process.env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY;
  if (!email || !rawKey) {
    throw new Error(
      "Missing Google Sheets env (GOOGLE_SERVICE_ACCOUNT_EMAIL / GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY)",
    );
  }
  return new google.auth.JWT({
    email,
    key: rawKey.replace(/\\n/g, "\n"),
    scopes: [SCOPE],
  });
}

/** Sheets returns locale-formatted timestamps; fall back to row order on junk. */
function parseTimestamp(raw: string): Date | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;
  const d = new Date(trimmed);
  return Number.isNaN(d.getTime()) ? null : d;
}

/**
 * Split one checkbox cell into the option strings it contains.
 *
 * Sheets joins multiple selections with ", ". That is only unambiguous because
 * no option contains a comma — see the warning in lib/fresh-jv-meals.ts. Every
 * token is matched against the known option list, and anything unrecognised is
 * logged loudly rather than dropped: an unknown token means the form's wording
 * and the site's have drifted apart, which silently breaks prefill too.
 */
function parseDateCell(raw: string): string[] {
  const tokens = raw
    .split(",")
    .map((t) => t.trim())
    .filter(Boolean);

  const dates: string[] = [];
  for (const token of tokens) {
    const slot = FRESH_JV_MEAL_SLOTS.find((s) => s.optionText === token);
    if (slot) {
      dates.push(slot.date);
    } else {
      console.error(
        `[fresh-jv-meals] Unrecognised date option ${JSON.stringify(token)} in the ` +
          `responses sheet. The form's option text has drifted from ` +
          `lib/fresh-jv-meals.ts — prefill links are probably broken too.`,
      );
    }
  }
  return dates;
}

/**
 * Pure resolution of raw sheet rows into per-date claims.
 *
 * Split out from the fetch on purpose: first-wins is THE rule this feature
 * rests on, and a rule that can only be exercised by hitting the network is a
 * rule that never gets tested. This takes the raw `values` array exactly as the
 * Sheets API returns it, header row included.
 */
export function resolveSignups(rows: string[][]): FreshJvMealSignups {
  const header = rows[0];
  if (!header) {
    // A sheet with no header row is a broken sheet, not an empty one.
    console.error("[fresh-jv-meals] Responses sheet has no header row");
    return { ok: false, reason: "Signup sheet has no header row" };
  }

  const idx: Record<keyof typeof COL_HEADERS, number> = {} as never;
  for (const [key, title] of Object.entries(COL_HEADERS)) {
    const found = header.findIndex((h) => (h ?? "").trim() === title);
    if (found === -1) {
      console.error(
        `[fresh-jv-meals] Missing required column ${JSON.stringify(title)}. ` +
          `Header row is: ${JSON.stringify(header)}`,
      );
      return { ok: false, reason: `Signup sheet is missing "${title}"` };
    }
    idx[key as keyof typeof COL_HEADERS] = found;
  }

  // Sort by submission time, falling back to sheet order (which is already
  // chronological) so a junk timestamp cannot jump the queue.
  const dataRows = rows.slice(1).map((row, order) => ({ row, order }));
  dataRows.sort((a, b) => {
    const ta = parseTimestamp(a.row[idx.timestamp] ?? "")?.getTime();
    const tb = parseTimestamp(b.row[idx.timestamp] ?? "")?.getTime();
    if (ta != null && tb != null && ta !== tb) return ta - tb;
    return a.order - b.order;
  });

  const claimsByDate = new Map<string, FreshJvMealClaim>();

  for (const { row } of dataRows) {
    if ((row[idx.cancelled] ?? "").trim().toLowerCase() === "yes") continue;

    const name = (row[idx.name] ?? "").trim();
    if (!name) continue;

    const displayName = formatShortName(name);
    if (!displayName) continue;

    const claimedAt = parseTimestamp(row[idx.timestamp] ?? "");

    for (const date of parseDateCell(row[idx.dates] ?? "")) {
      // First writer wins. A later row for the same date is a loser and is
      // deliberately ignored here - the Apps Script tells that person.
      if (!claimsByDate.has(date)) {
        claimsByDate.set(date, { date, displayName, claimedAt });
      }
    }
  }

  return { ok: true, claimsByDate };
}

export const getFreshJvMealSignups = cache(async (): Promise<FreshJvMealSignups> => {
  if (FRESH_JV_MEALS_SHEET_ID.includes("__REPLACE_")) {
    return { ok: false, reason: "FRESH_JV_MEALS_SHEET_ID is still a placeholder" };
  }

  try {
    const sheets = google.sheets({ version: "v4", auth: buildAuth() });
    const res = await sheets.spreadsheets.values.get({
      spreadsheetId: FRESH_JV_MEALS_SHEET_ID,
      range: READ_RANGE,
    });
    return resolveSignups((res.data.values ?? []) as string[][]);
  } catch (err) {
    console.error("[fresh-jv-meals] Sheet read failed", err);
    return { ok: false, reason: "Could not read the signup sheet" };
  }
});
