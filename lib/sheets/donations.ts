import "server-only";

import { cache } from "react";
import { google } from "googleapis";
import { format } from "date-fns";

import { DONATION_SHEET_ID } from "@/lib/constants";

/**
 * Read-only access to the donation Form-responses Google Sheet.
 *
 * Auth: service account JWT (same `mcneil-site-reader@…` account as
 * `boosters.ts`). The sheet is shared at Viewer; no project-level IAM. Sheet
 * ID is a code constant (not env) because it's not secret and the URL is
 * already visible to anyone editing the sheet.
 *
 * Treasurer gates publication via the `Payment Received` column — only "Yes"
 * rows surface. Donors gate display via `Display my donation publicly`. The
 * page-side `Donation` shape is the redacted view; the raw row never escapes
 * this module.
 */

const SHEET_TAB = "Form Responses 1";
const READ_RANGE = `'${SHEET_TAB}'!A:L`;
const SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly";

/**
 * ⚠️ These strings must match the sheet's header row EXACTLY. They are the
 * Google Form's question titles, so editing a question in the form rewrites the
 * header here and breaks the match.
 *
 * That is not hypothetical: `displayAnonymous` read "Display as anonymous" while
 * the live header was "Display as anonymous?" (trailing question mark, added by a
 * later form edit). Because that column is required, the whole reader bailed and
 * returned [] — so the public "Thank You to Our Donors" list silently showed
 * "Be the first to donate" for EVERY donor, including people who had already
 * given. Found 2026-08-08 while trying to publish a real donation.
 *
 * Matching is deliberately EXACT rather than normalized/fuzzy. `displayAnonymous`
 * gates whether a donor's real name is published, so a near-match that silently
 * resolves to the wrong column could out someone who asked to stay anonymous.
 * Failing hard is the correct behavior; the constant just has to be right.
 *
 * If the donor list ever goes empty unexpectedly, CHECK THESE AGAINST THE SHEET
 * FIRST — dump row 1 of "Form Responses 1" and diff.
 */
const COL_HEADERS = {
  yourName: "Your Name",
  donationAmount: "Donation Amount",
  otherAmount: "Other Amount (if selected above)",
  displayPublicly: "Display my donation publicly",
  displayAnonymous: "Display as anonymous?",
  dedication: "Dedication (optional)",
  paymentReceived: "Payment Received",
  paymentReceivedDate: "Payment Received Date",
} as const;

const DISPLAY_PUBLIC_YES = "yes, list me on the website";

export interface Donation {
  displayName: string;
  amountCents: number;
  monthYear: string;
  dedication: string | null;
  paymentReceivedDate: Date;
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

function parseAmountCents(raw: string): number | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;
  // Strip currency symbol + commas; leading number wins (e.g. "$250" or "250").
  const match = trimmed.match(/-?\d+(?:\.\d+)?/);
  if (!match) return null;
  const cleaned = match[0]!.replace(/,/g, "");
  const n = parseFloat(cleaned);
  if (!Number.isFinite(n) || n <= 0) return null;
  return Math.round(n * 100);
}

/**
 * Sheets API returns dates as locale-formatted strings (typically `M/D/YYYY`)
 * unless the cell is set to a specific format. Falls back to manual `/` or
 * `-` splitting if the Date constructor returns Invalid Date.
 */
function parseSheetDate(raw: string): Date | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;
  const direct = new Date(trimmed);
  if (!Number.isNaN(direct.getTime())) return direct;
  const sep = trimmed.includes("/") ? "/" : trimmed.includes("-") ? "-" : null;
  if (!sep) return null;
  const parts = trimmed.split(sep);
  if (parts.length !== 3) return null;
  const a = parseInt(parts[0]!, 10);
  const b = parseInt(parts[1]!, 10);
  const c = parseInt(parts[2]!, 10);
  if (!Number.isFinite(a) || !Number.isFinite(b) || !Number.isFinite(c)) {
    return null;
  }
  // Heuristic: 4-digit first field = ISO (Y-M-D); else US (M/D/Y).
  const [year, month, day] =
    a > 1900 ? [a, b, c] : [c < 100 ? 2000 + c : c, a, b];
  const d = new Date(year, month - 1, day);
  return Number.isNaN(d.getTime()) ? null : d;
}

export const getConfirmedDonations = cache(
  async (limit?: number): Promise<Donation[]> => {
    if (DONATION_SHEET_ID.includes("__REPLACE_")) {
      console.warn(
        "[donations] DONATION_SHEET_ID still placeholder; returning []",
      );
      return [];
    }
    try {
      const auth = buildAuth();
      const sheets = google.sheets({ version: "v4", auth });
      const res = await sheets.spreadsheets.values.get({
        spreadsheetId: DONATION_SHEET_ID,
        range: READ_RANGE,
      });
      const rows = (res.data.values ?? []) as string[][];
      const header = rows[0];
      if (!header || rows.length < 2) return [];

      const idx = (name: string) => header.indexOf(name);
      const iYourName = idx(COL_HEADERS.yourName);
      const iDonationAmount = idx(COL_HEADERS.donationAmount);
      const iOtherAmount = idx(COL_HEADERS.otherAmount);
      const iDisplayPublicly = idx(COL_HEADERS.displayPublicly);
      const iDisplayAnonymous = idx(COL_HEADERS.displayAnonymous);
      const iDedication = idx(COL_HEADERS.dedication);
      const iPaymentReceived = idx(COL_HEADERS.paymentReceived);
      const iPaymentReceivedDate = idx(COL_HEADERS.paymentReceivedDate);

      const missing: string[] = [];
      if (iYourName < 0) missing.push(COL_HEADERS.yourName);
      if (iDonationAmount < 0) missing.push(COL_HEADERS.donationAmount);
      if (iDisplayPublicly < 0) missing.push(COL_HEADERS.displayPublicly);
      if (iDisplayAnonymous < 0) missing.push(COL_HEADERS.displayAnonymous);
      if (iPaymentReceived < 0) missing.push(COL_HEADERS.paymentReceived);
      if (iPaymentReceivedDate < 0)
        missing.push(COL_HEADERS.paymentReceivedDate);
      if (missing.length > 0) {
        console.error(
          "[donations] required headers missing in sheet:",
          missing,
        );
        return [];
      }

      const out: Donation[] = [];
      for (const r of rows.slice(1)) {
        const paymentReceived = (r[iPaymentReceived] ?? "")
          .toString()
          .trim()
          .toLowerCase();
        if (paymentReceived !== "yes") continue;

        const displayPublicly = (r[iDisplayPublicly] ?? "")
          .toString()
          .trim()
          .toLowerCase();
        if (displayPublicly !== DISPLAY_PUBLIC_YES) continue;

        const paymentDate = parseSheetDate(
          (r[iPaymentReceivedDate] ?? "").toString(),
        );
        if (!paymentDate) continue;

        const donationAmountRaw = (r[iDonationAmount] ?? "").toString();
        const isOther = donationAmountRaw.trim().toLowerCase() === "other";
        const amountSource = isOther
          ? iOtherAmount >= 0
            ? (r[iOtherAmount] ?? "").toString()
            : ""
          : donationAmountRaw;
        const amountCents = parseAmountCents(amountSource);
        if (amountCents === null) continue;

        const anonymous = (r[iDisplayAnonymous] ?? "")
          .toString()
          .trim()
          .toLowerCase()
          .startsWith("yes");
        const displayName = anonymous
          ? "Anonymous"
          : (r[iYourName] ?? "").toString().trim();

        const dedicationRaw =
          iDedication >= 0 ? (r[iDedication] ?? "").toString().trim() : "";
        const dedication = dedicationRaw.length > 0 ? dedicationRaw : null;

        out.push({
          displayName,
          amountCents,
          monthYear: format(paymentDate, "LLLL yyyy"),
          dedication,
          paymentReceivedDate: paymentDate,
        });
      }

      out.sort(
        (a, b) =>
          b.paymentReceivedDate.getTime() - a.paymentReceivedDate.getTime(),
      );

      return typeof limit === "number" ? out.slice(0, limit) : out;
    } catch (err) {
      console.error("[donations] sheet read failed", err);
      return [];
    }
  },
);
