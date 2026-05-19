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
 * "Sultana Christensen" -> "Sultana C."
 * "Sylvia Brito " (trailing space) -> "Sylvia B."
 * "Madonna" (single token) -> "Madonna"
 * "" / "   " -> null
 */
export function formatShortName(full: string): string | null {
  const trimmed = full.trim();
  if (!trimmed) return null;
  const parts = trimmed.split(/\s+/);
  if (parts.length === 1) return parts[0]!;
  const last = parts[parts.length - 1]!;
  const firstParts = parts.slice(0, -1).join(" ");
  const initial = last[0]?.toUpperCase() ?? "";
  return initial ? `${firstParts} ${initial}.` : firstParts;
}

/**
 * Surname = substring after the LAST whitespace in the full name, per the
 * page-level sort contract decided 2026-05-19. Multi-word surnames like
 * "Van Buren" sort under "Buren". Single-token names return as-is.
 */
export function extractSurname(full: string): string {
  const trimmed = full.trim();
  if (!trimmed) return "";
  const lastWs = trimmed.lastIndexOf(" ");
  return lastWs === -1 ? trimmed : trimmed.slice(lastWs + 1);
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
 * Fetch + dedupe booster signup rows from the linked Google Sheet.
 * Cached per-request via React `cache()` so the page can call it from
 * multiple sections without double-fetching.
 *
 * Failure mode: any sheet/auth error logs and returns []. Callers must
 * render an explicit empty/error state.
 */
export const getBoosterMembers = cache(async (): Promise<BoosterMemberRow[]> => {
  const sheetId = process.env.GOOGLE_SHEETS_BOOSTERS_ID;
  if (!sheetId) {
    console.error("[boosters] GOOGLE_SHEETS_BOOSTERS_ID missing");
    return [];
  }
  try {
    const auth = buildAuth();
    const sheets = google.sheets({ version: "v4", auth });
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

    const internal: SheetRowInternal[] = [];
    for (const r of data) {
      const tierRaw = (r[iTier] ?? "").toString();
      const tier = parseTierLabel(tierRaw);
      if (!tier) continue;
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
