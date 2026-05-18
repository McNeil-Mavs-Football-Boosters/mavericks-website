# Slice 1 Spec: /boosters/join (Membership Tier Ladder)

Written 2026-05-18. Phase 1 pivot: no payments in Phase 1. Google Form is the join flow. /boosters/join is a server-rendered tier ladder + CTA to the Form.

Replaces the original Step 6 in build_plan_v2.md (Stripe Checkout was scoped out 2026-05-18). Future custom join flow is Phase 2+.

## Source of truth

- Visual reference: `docs/2026 - 2027 Membership - McNeil HS Football Boosters.pdf` (board-ratified)
- Data: `membership_tiers` table (already exists; migration 018 seed gets replaced)
- Form URL: https://docs.google.com/forms/d/e/1FAIpQLSfJXyssXItMv8EUU3FHkPqMo_9DGpReNlUq283NimBwa-rx1Q/viewform

## Constant

Add to `lib/constants.ts` (create the file if it doesn't exist):

```
export const BOOSTER_FORM_URL = 'https://docs.google.com/forms/d/e/1FAIpQLSfJXyssXItMv8EUU3FHkPqMo_9DGpReNlUq283NimBwa-rx1Q/viewform'
```

Every Form CTA in slice 1 imports this constant. Future custom-form swap is one find-and-replace.

## Migration 034_membership_tiers_pdf_reseed.sql

(Shipped 2026-05-18 as commit `9837aba`. Renumbered from 030 because 030 was already taken by `030_split_year_relabel_football.sql`.)

Two statements:

```sql
delete from membership_tiers where year = '2026-27';

insert into membership_tiers
  (name, price_cents, description, perks, sort_order, year, requires_tshirt_size, requires_second_tshirt_size, badge_label, active)
values
  (...);
```

Seven rows in `sort_order`:

| # | name | price_cents | description | perks (jsonb array) | tshirt | 2nd | badge |
|---|---|---|---|---|---|---|---|
| 1 | Free Fan Base! | 0 | Join Mav Nation. | `["Receive the Mavs Football Booster newsletter and important Mavs updates!"]` | false | false | null |
| 2 | Game Day! | 2000 | Friday nights, Mavs colors. | `["Mavs Football Car Decal"]` | false | false | Most Popular |
| 3 | Offense ⇄ Defense! | 5000 | Back both sides of the ball. | `["1 Mavs Football Game Day Fan or Bell", "1 Exclusive Booster Car Decal"]` | false | false | null |
| 4 | Blitz! | 10000 | Bring the pressure. | `["1 Exclusive Booster T-Shirt Voucher", "2 Mavs Football Car Decals"]` | true | false | Best Value |
| 5 | Touchdown! | 25000 | Six points for the program. | `["2 Exclusive Booster T-Shirt Vouchers", "2 Exclusive Booster Car Decals"]` | true | true | Recommended |
| 6 | Playoffs! | 50000 | Push deep into November. | `["2 Exclusive Booster T-Shirt Vouchers", "2 Exclusive Booster Car Decals", "Sponsorship Announcement at Home Games"]` | true | true | null |
| 7 | Championship! | 100000 | Go all in for the ring. | `["2 Exclusive Booster T-Shirt Vouchers", "2 Exclusive Booster Car Decals", "Sponsorship Announcement at Home Games", "Premier Parking Space at All Home Games"]` | true | true | null |

All rows: `year = '2026-27'`, `active = true`. Use `'[...]'::jsonb` literal casting to match existing seed style.

DELETE (not TRUNCATE) so any rows in other years are preserved.

Verification after apply:

```sql
select count(*) from membership_tiers where year = '2026-27' and active = true;
-- expect 7

select name, price_cents, jsonb_array_length(perks) as perk_count, badge_label
from membership_tiers where year = '2026-27' order by sort_order;
-- spot-check: Championship! has perk_count = 4; Game Day! badge = 'Most Popular'
```

## Page /boosters/join

Server component. Path: `app/boosters/join/page.tsx`. Replace any stub from Step 4b.

Data fetch (server-side, anon-key Supabase client per the followups.md note about not using service-role in public pages — if anon-key client doesn't exist yet, defer the swap and note it in followups; don't block slice 1):

1. `site_settings` single row → read `current_board_year` (booster club year — currently `'2026-27'`; **not** `current_year`, which governs football data and is currently `'2025-26'`).
2. `membership_tiers` where `year = current_board_year` and `active = true` order by `sort_order` ascending.

Empty state (zero tiers returned): render `<p>Booster membership for the {current_board_year} season will open soon. Check back.</p>` and exit. No tier grid, no CTAs.

## Layout

Top to bottom:

**1. Banner**

Full-width band, **green #1E541E** background. Approx 140-180px tall on desktop, fluid on mobile.

This is an intentional one-off deviation from the navy primary brand pass — green matches the PDF, which is the visual reference for this page only. Document the deviation as a comment at the top of the page component.

Contents:
- Left: Mavericks horseshoe logo, white variant. Use existing logo asset from `public/`.
- Centered: `MCNEIL HIGH SCHOOL FOOTBALL BOOSTER CLUB` as h1, Lato Black uppercase, white, with subtle letter-spacing.
- Top-right corner: `{current_board_year}` text (e.g. "2026 - 2027"), Lato Bold, white, smaller.

Mobile: stack logo above title, year hidden or moved below title.

**2. Intro**

Below banner, container width:
- h2: `Be a Mavs Booster!` (Lato Bold uppercase, navy)
- Paragraph: `Sign up today and get ready for the {current_board_year} McNeil Mavericks Football Season. Thank you for supporting the MAVS!`

**3. Tier grid**

Responsive grid:
- `lg`: 3 columns
- `md`: 2 columns
- `sm`/default: 1 column

Each card:
- Header row: `${price_cents / 100} ${name}` formatted as `$20 Game Day!` — h3, Lato Black, navy text
- Badge (if `badge_label` not null): top-right of card, green-bg pill, white text, Lato Bold uppercase, small. Tooltip not required.
- Tagline (`description`): below header, gray-700, regular weight, italic optional
- Perks list: each `perks` array item on its own line, prefixed with `+ ` (text plus sign and a space, matching the PDF). Lato Regular.
- Bottom: full-width primary button, navy bg, white text, label `Join at ${name}`. Anchor element with `href={BOOSTER_FORM_URL}`, `target="_blank"`, `rel="noopener noreferrer"`. Include sr-only `(opens in new tab)`.

Cards with a badge get an emphasized 2px green border. Cards without get a subtle 1px border (navy at 10% opacity or similar).

**4. Closing**

- Centered h2 `GO MAVS!` in green, Lato Black uppercase, larger than other h2s
- Small text below: `Questions? Contact [boosters@mcneilmavericks.org](mailto:boosters@mcneilmavericks.org).`

## Footer link

Update the existing slim footer (from A.5) to include `Join the Booster Club` linking to `/boosters/join`. If the footer already has a links column, add it there. If not, add it as a single CTA line above the copyright.

## Accessibility

- Heading order: h1 (banner) → h2 (intro) → h3 (each tier name) → h2 (closing). No skipped levels.
- All buttons read full text including tier name (not bare "Join")
- Color contrast: white on `#1E541E` and `#011858` both pass WCAG AA
- New-tab links include sr-only `(opens in new tab)` text
- Lighthouse a11y target ≥ 90 (same bar as Step 14)

## Acceptance criteria

1. Migration 030 applies cleanly via psql. Verification queries return expected results.
2. `/boosters/join` renders 7 tier cards in ascending price order.
3. Each card shows price + name, tagline, perks list, "Join at..." button.
4. Game Day shows "Most Popular" badge; Blitz "Best Value"; Touchdown "Recommended". Other 4 have no badge.
5. Every "Join at..." button opens `BOOSTER_FORM_URL` in a new tab.
6. Layout works on mobile (1 col), tablet (2 col), desktop (3 col).
7. If `site_settings.current_board_year` changes, the page either renders that year's tiers or the empty state. No broken state.
8. Footer includes "Join the Booster Club" link.
9. No console errors on Vercel preview.

## Rollback

- Migration: write `034_rollback.sql` that DELETEs the 034 rows and re-INSERTs the migration 010 values (the original 6-row placeholder seed — note 010, not 018). Schema is unchanged so rollback is data-only.
- Page: revert the commit. Step 4b stub returns. Footer link reverts with the page commit.

## Implementation order

Two CC turns:

**Turn 1: migration** (✅ shipped 2026-05-18, commit `9837aba`)
1. Write `db/migrations/034_membership_tiers_pdf_reseed.sql` (renumbered from 030 due to collision)
2. Apply via the standard psql workflow (`set -a && source .env.local && set +a && psql "$SUPABASE_DB_URL" -f db/migrations/034_membership_tiers_pdf_reseed.sql`)
3. Run verification queries; report counts and the spot-check row
4. Commit + push

**Turn 2: page**
1. Add `BOOSTER_FORM_URL` to `lib/constants.ts`
2. Build `app/boosters/join/page.tsx` per layout above
3. Add footer link
4. Verify Vercel preview deploy
5. Commit + push

## Out of scope for slice 1

- Form CTA on `/boosters` landing page (slice 2 or later)
- Form CTA on `/boosters/members` (slice 2 — that page doesn't exist yet)
- Form CTA on `/resources` (small follow-up after slice 2)
- Form CTA on homepage (homepage isn't designed yet)
- Anon-key Supabase client swap (open in followups.md; don't block on it)
- Banner background image / hero treatment beyond solid green
- Any "what dues fund" copy (lives on `/boosters` landing, not here)

## First instruction for CC

> Implement Turn 1 of `boosters_join_spec.md`. Write `db/migrations/034_membership_tiers_pdf_reseed.sql`: DELETE FROM membership_tiers WHERE year = '2026-27', then INSERT the 7 rows per the spec's seed table. Apply via psql, run the two verification queries (count = 7, and the spot-check select). Report output. Commit and push. Don't start Turn 2 yet.

> (Turn 1 was shipped 2026-05-18 as commit `9837aba`. For Turn 2, the page must query `current_board_year` not `current_year` — booster year and football year are decoupled.)
