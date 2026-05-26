# /boosters/donate Spec

Written 2026-05-25. Phase 1 pattern matches /boosters/join (Google Form CTA) and /boosters/members (Sheets-backed list). No Stripe in Phase 1; Venmo is the working payment channel. Treasurer verifies each payment manually in the linked Google Sheet before any donation appears on the public list.

Supersedes the `/boosters/donate` stub in `content_map_v2.md` (which described the Phase 2 Stripe-Checkout flow). The Phase 2 swap-out plan is documented at the bottom.

## Goal

Single page that asks visitors to donate to McNeil football, lists six amount options (all linking to a single Google Form), shows a public thank-you list of confirmed donors, and routes visitors who want a deeper commitment to `/boosters/join`.

## Route

`/boosters/donate`

Closes:
- Booster Club header dropdown → "Donate" 404
- Existing carousel CTA card already targets this route

## Form URL constant

To be added to `lib/constants.ts` in Turn 2 after the Form is built:

```
export const DONATION_FORM_URL = "https://docs.google.com/forms/d/e/<FORM_ID>/viewform";
```

All six amount-card CTAs and both "DONATE" header/footer buttons link to this constant. `target="_blank" rel="noopener noreferrer"`.

## Turn 1 — Google Form build (Jeremy, no code)

Build under `mcneilfootballboosters@gmail.com` (the gmail account that backs the booster + volunteer forms). Same pattern as `VOLUNTEER_FORM_URL` build on 2026-05-24.

Form title: **McNeil Football Booster Club — Donation**

Description (shown under title on the Form):

> Thank you for supporting McNeil football! Fill out this form to submit your donation. Once we receive your payment via Venmo (@McNeil-Football) or mailed check, we will email you a receipt for your records.

Form settings:
- Collect email addresses: **on** (required, with verification disabled — Google's "verified" mode forces sign-in; we want anyone)
- Limit to 1 response: **off**
- Allow response editing: **off**
- Show progress bar: **off** (single-section form)
- Show link to submit another response: **off**

Confirmation message (Form settings → Presentation → "Confirmation message"):

> Thank you for your donation pledge to McNeil Football!
>
> To complete your donation, please send your payment via Venmo to @McNeil-Football. Include your name in the payment note so we can match it to your pledge.
>
> Prefer to mail a check? Make it payable to "McNeil Maverick Football Booster Club" and send to:
> #412, 6001 W Parmer Ln, Suite 370
> Austin TX 78727
>
> Once we receive your payment, we will email you a tax receipt for your records. The McNeil Football Booster Club is a 501(c)(3) nonprofit organization, EIN 26-4231242.
>
> Questions? Email mcneilfootballboosters@gmail.com.

### Form fields (in order)

| # | Question | Type | Required | Notes |
|---|---|---|---|---|
| 1 | Your Name | Short answer | yes | First and last. Used internally + on receipt. Displayed publicly only when "Display my donation publicly" = Yes AND "Anonymous" = No. |
| 2 | Email Address | (auto, from Form setting) | yes | Used for receipt. Never displayed publicly. |
| 3 | Donation Amount | Multiple choice | yes | Options: `$25`, `$50`, `$100`, `$250`, `$500`, `Other`. |
| 4 | Other Amount (if selected above) | Short answer | no | Show only when "Donation Amount" = Other. Use Form's "Go to section based on answer" or just leave as conditional short-answer with a note. Validate: numeric, $5 minimum, no upper bound. |
| 5 | Display my donation publicly | Multiple choice | yes | Options: `Yes, list me on the website`, `No, keep my donation private`. Default highlighted: Yes. |
| 6 | Display as anonymous | Multiple choice | no | Options: `Yes, show as "Anonymous"`, `No, show my name`. Only relevant when field 5 = Yes. Default: No (show my name). |
| 7 | Dedication (optional) | Short answer | no | "In honor of, in memory of, etc. (optional, will appear on the public list under your donation)" |
| 8 | Employer Match Company (optional) | Short answer | no | "If your employer matches charitable donations, enter the company name here so we can follow up." |

### Linked Google Sheet

Form Responses sheet. **Add three columns to the right of the auto-generated columns** (treasurer-managed):

| Column | Type | Purpose |
|---|---|---|
| `Payment Received` | text (Yes/No) | Treasurer types "Yes" once Venmo/check confirmed. Page reads only rows where this = "Yes". |
| `Payment Received Date` | date | Date treasurer marked as received. Used for the "month" displayed on the public list. |
| `Treasurer Notes` | text | Internal scratchpad (Venmo transaction ID, check number, etc.). Never read by the site. |

Sheet name (the tab): `Form Responses 1` (Form default — don't rename, the Sheets API code keys off it).

Share the sheet with the existing service account (`mcneil-site-reader@…iam.gserviceaccount.com`) at Viewer permission. Same service account already used for `/boosters/members`.

### Turn 1 acceptance

- Form is live and accepting submissions
- Test submission with each amount option lands in the sheet
- Three treasurer-managed columns are present and labeled correctly
- Sheet is shared with the service account
- Form URL is captured and ready for Turn 2

## Turn 2 — Page build (CC)

Server component. Path: `app/boosters/donate/page.tsx`. Replaces the current 404.

### Data fetch

Server-side. Two reads:

1. `site_settings` for `current_board_year` (used for the page heading reference, e.g., "for the 2026-27 season"). Same pattern as `/boosters/join`.
2. Google Sheet via a new `lib/sheets/donations.ts` module. Mirrors `lib/sheets/boosters.ts` structure (JWT auth, same service account, same env vars).

ISR: `export const revalidate = 300` (5 min, matches members page).

### `lib/sheets/donations.ts`

New file. Exports a single async function:

```
export async function getConfirmedDonations(limit?: number): Promise<Donation[]>
```

Where `Donation` is:

```
type Donation = {
  displayName: string;          // "Anonymous" if anonymous flag, else the donor's name
  amountCents: number;          // parsed from amount column
  monthYear: string;            // e.g. "August 2026", derived from Payment Received Date
  dedication: string | null;    // optional, null if blank
  paymentReceivedDate: Date;    // used for sorting
};
```

Logic:
1. Read the sheet via the same `googleapis` client + JWT auth as `boosters.ts`. Reuse the env vars (`GOOGLE_SHEETS_PRIVATE_KEY`, `GOOGLE_SHEETS_CLIENT_EMAIL`).
2. Sheet ID: separate constant `DONATION_SHEET_ID` in `lib/constants.ts` (added in Turn 2 alongside the Form URL).
3. Range: `'Form Responses 1'!A:L` (covers Form columns A–I plus treasurer's J/K/L).
4. Skip header row.
5. Filter: include only rows where `Payment Received` column = `Yes` (case-insensitive, trim whitespace).
6. Skip rows where `Display my donation publicly` ≠ `Yes, list me on the website`.
7. For each surviving row:
   - `displayName` = if `Display as anonymous` starts with "Yes" → `"Anonymous"`, else the `Your Name` value (trim).
   - `amountCents` = if `Donation Amount` ≠ "Other" → parse the leading dollar amount; if "Other" → parse `Other Amount` column. Parse as: strip `$` and commas, parse float, multiply by 100, round. Skip the row if parse fails.
   - `monthYear` = format `Payment Received Date` as `"MMMM yyyy"` (e.g., "August 2026"). Skip the row if the date is blank or unparseable.
   - `dedication` = trim; null if empty.
8. Sort by `paymentReceivedDate` descending (most recent first).
9. If `limit` is passed, slice to that many.
10. Return.

Errors during fetch (network, auth, sheet permission): log and return `[]`. Page should render with the empty state, not crash.

### Layout (top to bottom)

#### 1. Hero band — GREEN

Same 3-col flex-row pattern as `/boosters/volunteer` and `/boosters/committees`.

- Background: `bg-mavs-green text-white`
- Left: `mhs-logo.png` with white-disc treatment (`rounded-full bg-white p-0.5`, `h-16 w-16 md:h-20 md:w-20`)
- Center: title "Make a Donation" (text-4xl md:text-6xl, font-bold)
- Right: button "DONATE →" — `bg-mavs-navy text-white`, links to `DONATION_FORM_URL`, opens new tab
- Container matches `/sponsors` so the right button right-aligns with rightmost top-nav tab
- Mobile: stacks vertically, button full-width

This is the second GREEN page-header band in the site (after `/boosters/volunteer`). Donating is a "do something" page, not informational.

#### 2. Intro prose section

- White background, container-constrained, max-w-3xl
- Three paragraphs verbatim:

> Your donation to the McNeil Maverick Football Booster Club helps fund team meals, banquets, extra equipment, player recognition, game day needs, travel support, and other football-specific expenses that help create a stronger, more meaningful experience for the young men in this program.

> Every contribution stays with McNeil football. Whether you give $25 or $5,000, your support shows up on the field, in the locker room, and at every team event throughout the season.

> The McNeil Maverick Football Booster Club is a 501(c)(3) nonprofit organization, EIN 26-4231242.

Note: deliberately does **not** include "tax-deductible to the full extent allowed by law" or similar IRS-specific phrasing per Jeremy's call. The 501(c)(3) + EIN statement is sufficient signal; donors who need deductibility specifics will ask.

#### 3. Amount cards section

- Section heading: "Choose an Amount" (text-3xl md:text-4xl, font-bold, navy, centered)
- Subhead: "All donations go through the same form. Select the amount that works for you."
- Card grid: `grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6`
- 6 cards in this exact order. 2 rows of 3 on desktop, 3 rows of 2 on tablet, single column on mobile.
- Each card: white bg, rounded-lg, 2px solid border (border-mavs-navy/30), p-8, hover lift (`hover:shadow-md transition-shadow`), text centered
- Card content (top to bottom):
  - Large dollar amount (or "Other") — `font-black text-mavs-navy text-5xl md:text-6xl`
  - Spacer
  - Primary button at bottom — `bg-mavs-green text-white`, full-width, label `Donate $25`, `Donate $50`, etc., or `Choose Amount` for the Other card. All link to `DONATION_FORM_URL`, new tab.
- The Other Amount card: same border treatment as the others (no visual distinction). The button label is the differentiator.

| Card | Display | Button label |
|---|---|---|
| 1 | $25 | Donate $25 |
| 2 | $50 | Donate $50 |
| 3 | $100 | Donate $100 |
| 4 | $250 | Donate $250 |
| 5 | $500 | Donate $500 |
| 6 | Other | Choose Amount |

All six buttons link to the same `DONATION_FORM_URL`. The amount is selected on the form itself; we are not pre-filling the form via URL parameters (Google Forms supports it but it adds fragility and the difference is one extra click).

#### 4. "Thank You to Our Donors" section

- Section heading: "Thank You to Our Donors" (text-3xl md:text-4xl, font-bold, navy, centered)
- Subhead under it: "Recent contributions to McNeil football. Every gift makes a difference."
- White background, container-constrained
- Render top 20 confirmed donations from `getConfirmedDonations(20)`.

Layout: single column list, max-w-3xl, centered. Each donation is a row with the following structure:

```
[Donor Name or "Anonymous"]                                    $250
[Dedication line, italic, gray-600 — only if present]
August 2026
─────────────────────────────────────────────────────────
```

- Donor name: left side, `font-bold text-lg text-mavs-navy`
- Amount: right side, `font-black text-lg text-mavs-navy`, comma-formatted (`$1,000` not `$1000`)
- Dedication: second line below name, `italic text-sm text-gray-600`, only rendered when not null
- Month/year: third line, `text-sm text-gray-500`
- Divider: `border-b border-gray-200` between rows, no divider on the last row

Empty state (zero confirmed donations from the sheet): render a single centered block:

> Be the first to donate. Your contribution will appear here once received.

with a "DONATE →" button below linking to the Form.

#### 5. Show more (Phase 2 placeholder)

After the list, render a disabled link/text:

```
<p class="text-center text-sm text-gray-500 mt-8">
  Full donation archive coming soon.
</p>
```

Wrapped behind a `donations.length === 20` conditional — only show when we hit the 20-item cap and there might actually be more.

When the archive page lands in Phase 2, swap to a real `<Link href="/boosters/donate/archive">Show all donations →</Link>`.

#### 6. Bottom CTA band — NAVY

- Background: `bg-mavs-navy text-white`
- Centered content
- Headline: "Want to do more?" (text-3xl md:text-4xl, font-bold)
- Subhead: "Become a McNeil Football Booster member for exclusive perks and a deeper connection to the program."
- Button: "JOIN THE CLUB →" — `bg-mavs-green text-white`, links to `/boosters/join` (internal Next `<Link>`, not new tab)

Same green-on-navy CTA pattern as `/boosters/volunteer` and `/boosters/sponsor` bottom CTAs.

### Constants added to lib/constants.ts

```
export const DONATION_FORM_URL = "https://docs.google.com/forms/d/e/<FORM_ID>/viewform";
export const DONATION_SHEET_ID = "<SHEET_ID>";
export const VENMO_HANDLE = "@McNeil-Football";
```

`VENMO_HANDLE` isn't displayed on the donate page itself (the Form confirmation handles that), but it's worth lifting to a constant for reuse on any future "how to donate today" copy and to make a change one find-and-replace.

### Components

- New page: `app/boosters/donate/page.tsx`
- New module: `lib/sheets/donations.ts`
- New inline component on the page: `DonationRow` — keep it inline like the other one-off display components on the sponsor/member pages. If a second consumer ever appears, lift to `components/donate/DonationRow.tsx`.
- Reuse: existing nav/footer, container utilities, no new shared components

## SEO

- Page title: "Donate | McNeil Mavericks Football Booster Club"
- Meta description: "Donate to McNeil Football. Your contribution funds team meals, equipment, player recognition, and more. McNeil Football Booster Club is a 501(c)(3) nonprofit."

## Accessibility

- Hero button has visible focus ring
- Logo `aria-hidden="true"` (decorative)
- All six amount-card buttons have descriptive labels (`Donate $25`, not "Donate")
- External Form links open in new tab — include `rel="noopener noreferrer"`
- Empty state's DONATE button has the same accessible name pattern
- Lighthouse a11y target ≥ 90 (same bar as `/boosters/volunteer`)

## Acceptance criteria

- [ ] `/boosters/donate` returns 200
- [ ] Header dropdown "Donate" link no longer 404s
- [ ] Hero band renders green with logo + title + Donate button (navy)
- [ ] All 6 amount cards render in the specified order
- [ ] All 6 amount-card buttons link to `DONATION_FORM_URL` and open in new tab
- [ ] Intro prose is verbatim from the spec
- [ ] "Thank You to Our Donors" list renders confirmed donations only
- [ ] Anonymous donations show "Anonymous" instead of name; amount and month still visible
- [ ] Dedication line renders italic-gray under the donor name when present, absent when blank
- [ ] Month displayed is the **Payment Received Date** month, not the form-submission month
- [ ] Empty state renders correctly when no rows are confirmed
- [ ] "Show more" placeholder appears only when there are 20 results
- [ ] Bottom CTA band renders navy with green "Join the Club" button linking to `/boosters/join`
- [ ] Mobile: hero stacks, cards collapse to 1 col, donation list stays readable
- [ ] No console errors, no a11y violations on Lighthouse
- [ ] Page-fetch failure (sheet unreachable) renders the empty state, not a 500

## Receipt copy block (treasurer reference, NOT on the site)

Chevon pastes this into her receipt email after verifying a donation. Plain-text body. Not stored in code — lives in this spec doc and (eventually) in her email drafts.

```
Subject: Thank you for your donation to McNeil Football

Dear [Donor Name],

Thank you for your generous donation of $[Amount] to the McNeil Maverick
Football Booster Club, received on [Date].

The McNeil Maverick Football Booster Club is a 501(c)(3) nonprofit
organization, EIN 26-4231242. Please retain this email for your records.

No goods or services were provided in exchange for this contribution.

Your support directly funds team meals, banquets, equipment, player
recognition, and other football-specific needs that make a real difference
for our athletes.

Go Mavs!

McNeil Maverick Football Booster Club
mcneilfootballboosters@gmail.com
```

The "No goods or services" line is the IRS-required language for written acknowledgments of donations $250 and over. Including it on every receipt is simpler than maintaining two templates and harms nothing for smaller donations.

When Stripe + Resend automation lands in Phase 2, this exact copy becomes the email template body.

## Data model — Phase 1 vs Phase 2

**Phase 1 (this spec):**
- Source of truth: Google Form responses sheet
- Treasurer's `Payment Received = Yes` flag is the gate for public display
- No DB writes from this page
- Manual receipt email by treasurer

**Phase 2 (post-Stripe):**
- Source of truth: `donations` table (new) or `payments` table with `purpose = 'donation'`
- Stripe webhook flips `status = 'succeeded'`, which becomes the page filter
- Auto-generated receipt email via Resend on webhook fire
- Same page shape; the only swap is `lib/sheets/donations.ts` → a Supabase query function with the same return type
- Google Form retired; on-site form replaces it (mirrors the Phase 2 `/boosters/join` plan)

The `Donation` type, the page layout, the amount cards, the empty state, the "Show more" placeholder, and the receipt-copy block all carry over unchanged. Only the data fetch changes.

## Out of scope for v1

- On-site donation form (Phase 2 — paired with Stripe)
- Automated receipt email via Resend (Phase 2)
- Donation archive page at `/boosters/donate/archive` (Phase 2 — Show more placeholder is there for it)
- Recurring/monthly donations (Phase 2+)
- Donation goals / progress bars / "we've raised $X this season" widgets
- Tribute / "in memory of" landing pages
- Donor login / "see my donation history" (no donor accounts in Phase 1 or Phase 2)
- Anonymous-but-show-amount-by-default (the form makes anonymity opt-in; this is correct)
- Pre-filling the Google Form with the clicked amount via URL parameter (deliberate — the form is the truth, the cards are just a visual sorter)
- Cross-promotion of `/boosters/sponsor` from this page (sponsorship is a different audience; keep the page focused)
- Phone-number capture on the Form (donations don't need it; reduces friction)
- Address capture on the Form (not IRS-required for ≥$250 receipts, treasurer can ask if she ever needs it)

## Implementation order

Two phases, two CC turns:

**Turn 1: Google Form (Jeremy, not CC).** Build the Form per the spec. Add the three treasurer columns to the sheet. Share with the service account. Capture the Form URL + Sheet ID. Submit one test donation, mark it Payment Received = Yes with today's date, and verify the row is shaped as expected.

**Turn 2: Page + sheet reader (CC).**
1. Add `DONATION_FORM_URL`, `DONATION_SHEET_ID`, `VENMO_HANDLE` to `lib/constants.ts`
2. Write `lib/sheets/donations.ts` mirroring `boosters.ts` structure
3. Build `app/boosters/donate/page.tsx` per the layout spec
4. Verify Vercel preview deploy
5. Smoke test: the Turn 1 test donation appears on the page; switching Payment Received to "No" makes it disappear within ISR window
6. Commit + push

## Rollback

- Turn 1 (Form): no rollback needed. If we want to retire the Form, just don't link to it.
- Turn 2 (page): revert the commit. `/boosters/donate` returns 404 again. Header dropdown link reverts with the commit (or stays in place and 404s — depending on which file is reverted).

## First instruction for CC

Turn 1 is for Jeremy. After Jeremy reports the Form URL + Sheet ID + a successful test row, the Turn 2 prompt is:

> Implement Turn 2 of `boosters_donate_spec.md`. Add `DONATION_FORM_URL`, `DONATION_SHEET_ID`, and `VENMO_HANDLE` to `lib/constants.ts` using the values Jeremy reported. Build `lib/sheets/donations.ts` mirroring the structure of `lib/sheets/boosters.ts` (JWT auth, same service account, same env vars). Build `app/boosters/donate/page.tsx` per the layout: green hero with Donate button, intro prose, 6-card grid (3-col desktop / 2-col tablet / 1-col mobile), "Thank You to Our Donors" list (top 20, confirmed only), empty state, "Show more" placeholder when 20 results returned, navy bottom CTA linking to `/boosters/join`. ISR revalidate 300. Verify Vercel preview, confirm the test donation appears on the page, confirm flipping Payment Received to "No" in the sheet removes it after revalidate. Commit and push.
