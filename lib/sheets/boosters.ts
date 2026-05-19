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
 * Returns minimally-parsed rows: tier name + price (parsed from the
 * dropdown label), plus parent names formatted as "First L." per the
 * page-level privacy contract decided 2026-05-18. Higher-level grouping +
 * sort + tier join lives in the page component so the lib stays focused
 * on sheet I/O.
 */

const SHEET_TAB = "Form Responses 1";
const READ_RANGE = `'${SHEET_TAB}'!A1:Z`;
const SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly";

const COL_HEADERS = {
  timestamp: "Timestamp",
  tier: "Which Mav Booster level would you like to join?",
  parent1: "Parent 1 Name",
  parent2: "Parent 2 Name",
} as const;

export interface BoosterMemberRow {
  /** Sheet timestamp string, raw. */
  timestamp: string;
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
 * Form label format: "Touchdown! - $250.00", "Free Fan Base! - $0.00".
 * Tolerant of missing price suffix (returns priceCents=0).
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
 * Fetch all booster signup rows from the linked Google Sheet.
 * Cached per-request via React `cache()` so the page can call it from
 * multiple sections without double-fetching.
 *
 * Failure mode: any sheet/auth error logs and returns []. Callers must
 * render an explicit empty/error state — no row count is treated as a
 * data signal vs a config signal.
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
    const iTier = idx(COL_HEADERS.tier);
    const iParent1 = idx(COL_HEADERS.parent1);
    const iParent2 = idx(COL_HEADERS.parent2);
    if (iTier < 0 || iParent1 < 0) {
      console.error("[boosters] required headers missing in sheet", {
        hasTimestamp: iTimestamp >= 0,
        hasTier: iTier >= 0,
        hasParent1: iParent1 >= 0,
        hasParent2: iParent2 >= 0,
      });
      return [];
    }

    const out: BoosterMemberRow[] = [];
    for (const r of data) {
      const tierRaw = (r[iTier] ?? "").toString();
      const tier = parseTierLabel(tierRaw);
      if (!tier) continue;
      const parent1 = formatShortName((r[iParent1] ?? "").toString());
      const parent2 =
        iParent2 >= 0
          ? formatShortName((r[iParent2] ?? "").toString())
          : null;
      out.push({
        timestamp:
          iTimestamp >= 0 ? (r[iTimestamp] ?? "").toString() : "",
        rawTierLabel: tierRaw,
        tierName: tier.name,
        tierPriceCents: tier.priceCents,
        parent1Short: parent1,
        parent2Short: parent2,
      });
    }
    return out;
  } catch (err) {
    console.error("[boosters] sheet read failed", err);
    return [];
  }
});
