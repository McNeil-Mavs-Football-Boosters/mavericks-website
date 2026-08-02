import "server-only";

import { cache } from "react";
import { google } from "googleapis";

/**
 * Read-only access to the booster Form-responses Google Sheet.
 *
 * Auth: service account JWT (lib/sheets/... is server-only). The sheet is
 * shared with mcneil-site-reader@... at Viewer role; no project-level IAM
 * roles. Sheet ID + service account creds come from env vars wired in
 * 2026-05-18 (commit 8b79407).
 *
 * Public BoosterMemberRow fields are the redacted/derived shape: tier name +
 * price (parsed from the dropdown label), short-name display strings, and a
 * surname extracted from Parent 1 for sort. The raw email + full names are
 * used internally for dedupe and are not re-exported.
 *
 * Dedupe: people sometimes submit twice. Primary key = lowercased Email
 * Address column; fallback key = lowercased trimmed Parent 1 Name. Within a
 * key group, the row with the latest parseable Timestamp wins.
 */

const SHEET_TAB = "Form Responses 1";
const READ_RANGE = `'${SHEET_TAB}'!A1:Z`;
const SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly";

const COL_HEADERS = {
  timestamp: "Timestamp",
  email: "Email Address",
  tier: "Which Mav Booster level would you like to join?",
  parent1: "Parent 1 Name",
  parent2: "Parent 2 Name",
} as const;

export interface BoosterMemberRow {
  /** Raw dropdown label, e.g. "Touchdown! - $250.00". */
  rawTierLabel: string;
  /** Tier name extracted from the label, e.g. "Touchdown!". Matches membership_tiers.name. */
  tierName: string;
  /** Price in cents parsed from the label, e.g. 25000. May be 0 for Free Fan Base!. */
  tierPriceCents: number;
  /** Parent 1 name formatted as "First L.", or null if blank. */
  parent1Short: string | null;
  /** Parent 2 name formatted as "First L.", or null if blank/missing. */
  parent2Short: string | null;
  /**
   * Surname extracted from Parent 1 Name — the substring after the LAST
   * whitespace ("Sarah Van Buren" -> "Buren", "Marina Salazar" -> "Salazar").
   * Used for alphabetical sort. Empty string if Parent 1 is blank.
   */
  parent1Surname: string;
}

interface SheetRowInternal extends BoosterMemberRow {
  timestamp: string;
  /** Lowercased + trimmed email; "" when blank. Internal dedupe key. */
  emailKey: string;
  /** Lowercased + trimmed Parent 1 Name. Internal fallback dedupe key. */
  parent1Key: string;
}

/**
 * Generational suffixes, mapped to their display form so "sr", "SR" and "Sr."
 * all render identically. Roman numerals take no period.
 *
 * "V" is deliberately absent. A lone trailing "V" is far more likely to be a
 * surname someone abbreviated than the numeral five, and mistaking one for the
 * other would drop a real last name.
 */
const GENERATIONAL_SUFFIXES: Record<string, string> = {
  sr: "Sr.",
  jr: "Jr.",
  ii: "II",
  iii: "III",
  iv: "IV",
};

interface SplitName {
  /** Everything before the surname: first name plus any middle names/initials. */
  given: string;
  /** Family name, or "" when the person listed only one token. */
  surname: string;
  /** Normalized generational suffix ("Sr.", "III"), or null. */
  suffix: string | null;
}

/**
 * Single place that decides which token of a name is the surname. Both the
 * display formatter and the sort key go through here so they can never
 * disagree about where the last name is.
 *
 * The suffix handling exists because "TreyVon Cargill Sr" was rendering as
 * "TreyVon Cargill S." -- the old last-token rule treated "Sr" as the family
 * name. A suffix is only peeled off when a real name remains underneath it.
 *
 * "Sarah Van Buren" -> given "Sarah Van", surname "Buren" (last token wins;
 * multi-word surnames file under their final word, per the 2026-05-19 sort
 * contract).
 */
export function splitName(full: string): SplitName {
  const parts = full.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return { given: "", surname: "", suffix: null };

  let suffix: string | null = null;
  const tail = parts[parts.length - 1]!.replace(/\.$/, "").toLowerCase();
  if (parts.length >= 2 && GENERATIONAL_SUFFIXES[tail]) {
    suffix = GENERATIONAL_SUFFIXES[tail]!;
    parts.pop();
  }

  if (parts.length === 1) return { given: parts[0]!, surname: "", suffix };
  const surname = parts.pop()!;
  return { given: parts.join(" "), surname, suffix };
}

/**
 * "Sultana Christensen"   -> "Sultana C."
 * "James R Davis"         -> "James R D."      (middle initial kept)
 * "TreyVon Cargill Sr"    -> "TreyVon C. Sr."  (suffix kept, not mistaken for the surname)
 * "Sylvia Brito " (trailing space) -> "Sylvia B."
 * "Madonna" (single token)-> "Madonna"          (no surname given, none invented)
 * "" / "   "              -> null
 */
export function formatShortName(full: string): string | null {
  const { given, surname, suffix } = splitName(full);
  if (!given && !surname) return null;
  const initial = surname ? `${surname[0]!.toUpperCase()}.` : "";
  return [given, initial, suffix].filter(Boolean).join(" ");
}

/**
 * Sort key: the family name, per the page-level sort contract decided
 * 2026-05-19. Multi-word surnames like "Van Buren" sort under "Buren", and a
 * generational suffix is ignored so "TreyVon Cargill Sr" sorts under Cargill,
 * not under Sr. See splitName() -- it is the only thing that decides which
 * token is the surname, so the sort key and the displayed initial always agree.
 *
 * Returns "" when no surname was given -- either a blank cell or a
 * single-token name like "Rob". Callers must treat "" as "no sort key" and
 * push the row to the end of the list, NOT sort it under the first name.
 *
 * Changed 2026-08-02 (was: single tokens returned as-is, so "Rob" sorted into
 * the R block). Per Jeremy: never give someone a last name they did not list.
 * In particular do NOT borrow Parent 2's surname for a Parent 1 who left it
 * blank -- the parents may be divorced or otherwise have different surnames,
 * so that inference can attach the wrong name to a real person.
 */
export function extractSurname(full: string): string {
  return splitName(full).surname;
}

/**
 * Form label format: "Touchdown! - $250.00", "Free Fan Base! - $0.00",
 * sometimes "$100" without decimals. Tolerant of missing price suffix.
 */
export function parseTierLabel(
  raw: string,
): { name: string; priceCents: number } | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;
  const m = trimmed.match(/^(.+?)\s+-\s+\$?(\d+(?:\.\d+)?)\s*$/);
  if (m) {
    return {
      name: m[1]!.trim(),
      priceCents: Math.round(parseFloat(m[2]!) * 100),
    };
  }
  return { name: trimmed, priceCents: 0 };
}

/**
 * Season aliases for a `current_board_year` value, for matching against the
 * spreadsheet's own title. "2026-27" -> ["2026-27", "2026-2027"] because the
 * club names its sheets with the long form ("… Membership 2026-2027 (Responses)")
 * while site_settings carries the short form.
 */
export function seasonAliases(boardYear: string): string[] {
  const m = boardYear.match(/^(\d{4})-(\d{2})$/);
  if (!m) return [boardYear];
  const [, start, endShort] = m;
  return [boardYear, `${start}-${start!.slice(0, 2)}${endShort}`];
}

/**
 * First instant that counts as this season's signup window: Jan 1 of the
 * season's start year. "2026-27" -> 2026-01-01.
 *
 * Deliberately generous. The 2026-27 drive opened 2026-04-08, so April would
 * have fit — but picking a tight cutoff just trades one silent failure for
 * another: an early-bird signup would vanish from the page with nobody the
 * wiser. Jan 1 cannot cut a real signup for the season it belongs to, and the
 * next season's cutoff (Jan 1 of ITS start year) still excludes every row from
 * this one. Rows dropped by the cutoff are counted and logged, never silent.
 *
 * Returns null for an unparseable year, which disables the filter rather than
 * dropping everything.
 */
export function seasonStart(boardYear: string): Date | null {
  const m = boardYear.match(/^(\d{4})-\d{2}$/);
  if (!m) return null;
  return new Date(`${m[1]}-01-01T00:00:00`);
}

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

/**
 * Latest-wins dedupe. Primary key = email; fallback key = parent1 name when
 * email is blank. Surfaces a console warning if rows with the same parent1
 * name carry different non-blank emails (per Jeremy 2026-05-19: "flag the
 * conflict, don't auto-resolve") — those rows pass through both ways and
 * get rendered as two entries.
 */
function dedupe(rows: SheetRowInternal[]): SheetRowInternal[] {
  const parsed = rows.map((r) => ({
    row: r,
    tsMs: Date.parse(r.timestamp),
  }));
  // Sort by parsed timestamp DESC (NaN sorts last as oldest). First-occurrence
  // of each key after this sort = latest version.
  parsed.sort((a, b) => {
    const at = Number.isNaN(a.tsMs) ? -Infinity : a.tsMs;
    const bt = Number.isNaN(b.tsMs) ? -Infinity : b.tsMs;
    return bt - at;
  });

  const seenKeys = new Set<string>();
  const kept: SheetRowInternal[] = [];
  for (const { row } of parsed) {
    const key = row.emailKey
      ? `email:${row.emailKey}`
      : row.parent1Key
        ? `name:${row.parent1Key}`
        : null;
    if (key === null) {
      kept.push(row);
      continue;
    }
    if (seenKeys.has(key)) continue;
    seenKeys.add(key);
    kept.push(row);
  }

  // After dedupe, check for the "same name, different emails" conflict —
  // can't auto-resolve, just log so it shows in Vercel build logs.
  const byParent1: Record<string, Set<string>> = {};
  for (const r of kept) {
    if (!r.parent1Key || !r.emailKey) continue;
    (byParent1[r.parent1Key] ??= new Set()).add(r.emailKey);
  }
  for (const [name, emails] of Object.entries(byParent1)) {
    if (emails.size > 1) {
      console.warn(
        `[boosters] dedupe conflict: parent1='${name}' has ${emails.size} distinct emails; both rows kept`,
      );
    }
  }
  return kept;
}

/**
 * Fetch + dedupe booster signup rows for `boardYear` from the linked Sheet.
 * Cached per-request via React `cache()` so the page can call it from
 * multiple sections without double-fetching.
 *
 * Failure mode: any sheet/auth error logs and returns []. Callers must
 * render an explicit empty/error state.
 *
 * ── Season safety (added 2026-08-02) ────────────────────────────────────────
 *
 * This function used to publish EVERY row in whatever sheet
 * GOOGLE_SHEETS_BOOSTERS_ID pointed at, with no concept of a season, while the
 * page headed the list with `current_board_year`. It was correct only by luck
 * of the env var happening to point at the right sheet. Both rollover paths
 * failed silently:
 *
 *   * New form + new sheet each season -> if nobody updates the env var, the
 *     page serves last season's members under this season's heading. Forever.
 *   * Same sheet reused -> two seasons stack up and the family count inflates.
 *
 * Neither errored. Two guards now:
 *
 *   1. The spreadsheet's TITLE must name the current season. The club names
 *      its sheets "… Membership 2026-2027 (Responses)", so a stale ID is
 *      caught by content rather than by anyone remembering. Mismatch -> log
 *      an error and return [], so the page shows its empty state with the
 *      join CTA instead of quietly publishing the wrong year.
 *   2. Rows older than the season start are dropped, and the count is logged.
 *
 * The guards agree: a stale sheet fails BOTH (wrong title, and every row
 * predates the cutoff), so there is no combination that publishes stale names.
 */
export const getBoosterMembers = cache(async (
  boardYear: string,
): Promise<BoosterMemberRow[]> => {
  const sheetId = process.env.GOOGLE_SHEETS_BOOSTERS_ID;
  if (!sheetId) {
    console.error("[boosters] GOOGLE_SHEETS_BOOSTERS_ID missing");
    return [];
  }
  try {
    const auth = buildAuth();
    const sheets = google.sheets({ version: "v4", auth });

    // Guard 1 — the sheet must be this season's sheet.
    const meta = await sheets.spreadsheets.get({
      spreadsheetId: sheetId,
      fields: "properties.title",
    });
    const sheetTitle = meta.data.properties?.title ?? "";
    const aliases = seasonAliases(boardYear);
    if (!aliases.some((a) => sheetTitle.includes(a))) {
      console.error(
        `[boosters] REFUSING TO PUBLISH: sheet "${sheetTitle}" does not name ` +
          `season ${boardYear} (looked for ${aliases.join(" or ")}). ` +
          `Point GOOGLE_SHEETS_BOOSTERS_ID at the ${boardYear} responses sheet.`,
      );
      return [];
    }

    const res = await sheets.spreadsheets.values.get({
      spreadsheetId: sheetId,
      range: READ_RANGE,
    });
    const rows = (res.data.values ?? []) as string[][];
    const header = rows[0];
    if (!header || rows.length < 2) return [];
    const data = rows.slice(1);
    const idx = (name: string) => header.indexOf(name);
    const iTimestamp = idx(COL_HEADERS.timestamp);
    const iEmail = idx(COL_HEADERS.email);
    const iTier = idx(COL_HEADERS.tier);
    const iParent1 = idx(COL_HEADERS.parent1);
    const iParent2 = idx(COL_HEADERS.parent2);
    if (iTier < 0 || iParent1 < 0) {
      console.error("[boosters] required headers missing in sheet", {
        hasTimestamp: iTimestamp >= 0,
        hasEmail: iEmail >= 0,
        hasTier: iTier >= 0,
        hasParent1: iParent1 >= 0,
        hasParent2: iParent2 >= 0,
      });
      return [];
    }

    // Guard 2 — drop rows from a previous season, and say how many.
    const cutoff = seasonStart(boardYear);
    let preSeasonDropped = 0;

    const internal: SheetRowInternal[] = [];
    for (const r of data) {
      const tierRaw = (r[iTier] ?? "").toString();
      const tier = parseTierLabel(tierRaw);
      if (!tier) continue;
      if (cutoff && iTimestamp >= 0) {
        const ts = Date.parse((r[iTimestamp] ?? "").toString());
        // An unparseable timestamp is kept: a real member with a malformed
        // date should not silently vanish over a formatting quirk.
        if (!Number.isNaN(ts) && ts < cutoff.getTime()) {
          preSeasonDropped++;
          continue;
        }
      }
      const parent1Full = (r[iParent1] ?? "").toString();
      const parent2Full =
        iParent2 >= 0 ? (r[iParent2] ?? "").toString() : "";
      const emailRaw =
        iEmail >= 0 ? (r[iEmail] ?? "").toString().trim() : "";
      internal.push({
        timestamp:
          iTimestamp >= 0 ? (r[iTimestamp] ?? "").toString() : "",
        emailKey: emailRaw.toLowerCase(),
        parent1Key: parent1Full.trim().toLowerCase(),
        rawTierLabel: tierRaw,
        tierName: tier.name,
        tierPriceCents: tier.priceCents,
        parent1Short: formatShortName(parent1Full),
        parent2Short: formatShortName(parent2Full),
        parent1Surname: extractSurname(parent1Full),
      });
    }

    if (preSeasonDropped > 0) {
      console.warn(
        `[boosters] ${preSeasonDropped} row(s) predate the ${boardYear} season ` +
          `(before ${cutoff!.toISOString().slice(0, 10)}) and were excluded. ` +
          `Expected right after a season rollover on a reused sheet; ` +
          `investigate if it appears mid-season.`,
      );
    }

    const deduped = dedupe(internal);
    // Strip internal-only fields before returning.
    return deduped.map(
      ({
        rawTierLabel,
        tierName,
        tierPriceCents,
        parent1Short,
        parent2Short,
        parent1Surname,
      }) => ({
        rawTierLabel,
        tierName,
        tierPriceCents,
        parent1Short,
        parent2Short,
        parent1Surname,
      }),
    );
  } catch (err) {
    console.error("[boosters] sheet read failed", err);
    return [];
  }
});
