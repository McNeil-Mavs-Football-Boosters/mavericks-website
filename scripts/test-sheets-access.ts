/**
 * Throwaway smoke test for Google Sheets API access.
 *
 * Verifies the same env vars + auth path that slice 2's /boosters/members
 * page will use. Delete this file after confirming output, in a follow-up
 * commit.
 *
 * Run: npx tsx scripts/test-sheets-access.ts
 */
import { config as dotenvConfig } from "dotenv";
import { google } from "googleapis";

dotenvConfig({ path: ".env.local" });

async function main() {
  const email = process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL;
  const rawKey = process.env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY;
  const sheetId = process.env.GOOGLE_SHEETS_BOOSTERS_ID;

  if (!email || !rawKey || !sheetId) {
    console.error(
      "Missing env: need GOOGLE_SERVICE_ACCOUNT_EMAIL, GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY, GOOGLE_SHEETS_BOOSTERS_ID",
    );
    process.exit(1);
  }

  // Handles both escaped (`\\n`) and raw-newline forms.
  const privateKey = rawKey.replace(/\\n/g, "\n");

  const auth = new google.auth.JWT({
    email,
    key: privateKey,
    scopes: ["https://www.googleapis.com/auth/spreadsheets.readonly"],
  });

  const sheets = google.sheets({ version: "v4", auth });

  const meta = await sheets.spreadsheets.get({
    spreadsheetId: sheetId,
    fields: "properties.title,sheets.properties",
  });
  console.log("TITLE:", meta.data.properties?.title);
  const firstTab = meta.data.sheets?.[0]?.properties?.title;
  console.log("FIRST TAB:", firstTab);

  if (!firstTab) {
    console.error("No tabs found");
    process.exit(1);
  }

  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: `'${firstTab}'!A1:E5`,
  });
  const rows = res.data.values ?? [];
  console.log(`ROW COUNT (cols A-E of first 5 rows): ${rows.length}`);
  if (rows[0]) {
    console.log("HEADER (cols A-E):", rows[0]);
  }
  console.log(`NON-HEADER ROW COUNT: ${Math.max(0, rows.length - 1)}`);
  console.log("SUCCESS");
}

main().catch((err) => {
  console.error("ERROR:", err instanceof Error ? err.message : err);
  process.exit(1);
});
