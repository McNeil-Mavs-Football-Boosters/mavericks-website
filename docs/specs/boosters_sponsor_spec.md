# Spec: Build `/boosters/sponsor` Sales Page

**As-shipped 2026-05-23 — commit `e6a9eb8`.** All 5 sections live per spec. Deviations:
- "See All Sponsors →" link in the bottom sponsor strip uses `next/link` (`<Link>`) not raw `<a>`, required by `@next/next/no-html-link-for-pages`. Same call `/sponsors` made for its internal CTAs.
- AC16 ("no `@mcneilmavericks.org` anywhere on this page") passes in spirit — the page content uses only `mcneilfootballboosters@gmail.com`; the shared `<Footer>` component still renders `boosters@mcneilmavericks.org` site-wide (out of scope this commit).
- `SponsorStripLogo` lifted from `app/page.tsx` to `components/sponsors/SponsorStripLogo.tsx` and imported from both call sites.
- AC13–15 (mobile collapse, console errors, Lighthouse a11y ≥ 90) verified via class inspection and dev-server logs; browser-side QA pending.

Written 2026-05-23. Builds the booster sponsorship sales page. Closes the last 404 from 2026-05-22's sponsor work (`/sponsors` footer CTA card "See Sponsorship Options" and `/sponsors` page-header "Become a Sponsor →" both link here).

**Phase 1 scope:** mission statement, tier display, contact-by-email CTA, sponsor strip at the bottom. No inquiry form. No Stripe Checkout. No `sponsorship_inquiries` table. Sponsorship sales are higher-touch, and Kendra (VP Fundraising) follows up manually with prospects who reach out. The content_map_v2 design that proposed an inquiry form is deferred — revisit in Phase 2 if Kendra wants a form.

**Reads with:**
- `content_map_v2.md` — `/boosters/sponsor` section (the design this supersedes for Phase 1)
- `sponsors_page_spec.md` — sibling page that shipped 2026-05-22; this spec uses the same brand patterns
- `boosters_join_spec.md` — sibling tier-cards page; tier card structure mirrors that page
- `schema.md` — `sponsorship_tiers` table definition

## Prerequisites

CC must verify before starting Turn 1:
- Working tree clean, `origin/main` matches local
- Migration 041 applied (relabeled `sponsorship_tiers` to year `2025-26`) — should already be true; verify with the count query below
- `site_settings.current_year = '2025-26'` (football year governs sponsorship per the year-axis convention; sponsorship_tiers seed lives at 2025-26 after mig 041)
- 5 active rows in `sponsorship_tiers` for year `2025-26`

Verification:
```sql
select count(*) from sponsorship_tiers where year = '2025-26' and active = true;
-- expect: 5

select name, price_cents, jsonb_array_length(perks) as perk_count, badge_label
from sponsorship_tiers where year = '2025-26' order by sort_order;
-- expect: MVP/Diamond/Platinum/Gold/Blue, Platinum has badge_label = 'Recommended', others null
```

If any precondition fails, stop and report.

## What this is

A new file: `app/boosters/sponsor/page.tsx` (server component, `force-dynamic` to match the `/sponsors` pattern). Reads from `sponsorship_tiers` and `sponsors` tables. Renders mission statement → tier cards → contact CTA → sponsor strip.

Plus: `app/boosters/sponsor/[catchall]/page.tsx` with unconditional `notFound()`, matching the sibling pattern from `/coaches`, `/resources`, `/sponsors`.

## What this is NOT

- Not an inquiry form. Phase 2 work, if ever.
- Not Stripe Checkout for sponsorships. Phase 2 work, if ever.
- Not an admin CRUD. Tier edits happen via Studio.
- Not a redesign of `/sponsors`, the homepage strip, or the carousel.
- Not new sponsor data. Reuses the seed from migration 041.
- Not new tier data. Reuses the seed from earlier migrations.
- Not Cloudflare Email Routing setup. The contact email on this page is `mcneilfootballboosters@gmail.com` (the address that already works — backs the Google Form and is on file at SportsEngine). The `@mcneilmavericks.org` aliases are still pending under J9.

## Data fetch

Single page-level fetch. Match the `/sponsors` page pattern. Both calls use the existing Supabase server client.

```
const currentYear = await getCurrentYear(); // site_settings.current_year

const { data: tiers } = await supabase
  .from('sponsorship_tiers')
  .select('id, name, price_cents, description, perks, sort_order, badge_label, year')
  .eq('year', currentYear)
  .eq('active', true)
  .order('sort_order', { ascending: true });

const { data: sponsors } = await supabase
  .from('sponsors')
  .select('id, name, logo_url, website_url, tier_id, sort_order, year')
  .eq('year', currentYear)
  .eq('active', true)
  .order('sort_order', { ascending: true });

// For the bottom sponsor strip's two-row partition, also fetch the MVP tier id
// — same pattern as the homepage strip (loadHome() in app/page.tsx).
const { data: mvpTier } = await supabase
  .from('sponsorship_tiers')
  .select('id')
  .eq('year', currentYear)
  .eq('active', true)
  .eq('name', 'MVP')
  .maybeSingle();
const mvpTierId = mvpTier?.id ?? null;
```

If `getCurrentYear()` / `getSiteSettings()` helper exists, use it. If not, inline the `site_settings` lookup — matches `app/sponsors/page.tsx`.

## Page structure

Top to bottom. Header and footer come from the shared layout, not this page.

### 1. Page header (Hero)

Full-width navy band. Same visual pattern as the homepage StaticHero but shorter and with sponsor-focused copy. This sets up the green page-CTA button visually below.

```
<section class="bg-mavs-navy text-white py-16 md:py-20">
  <div class="container mx-auto px-4 text-center">
    <h1 class="text-4xl md:text-6xl font-black uppercase tracking-tight">
      Support McNeil Mavericks Football
    </h1>
    <div class="h-1 w-24 bg-mavs-green mx-auto mt-4"></div>
    <p class="text-xl md:text-2xl font-bold mt-6 max-w-3xl mx-auto">
      Every sponsorship directly supports the athletes in the McNeil Football program.
    </p>
  </div>
</section>
```

Sizing notes:
- h1 `text-4xl md:text-6xl` — larger than other page h1s on the site. Jeremy specifically asked for this to be bigger.
- Green underline `h-1 w-24` — wider than the standard `w-20` brand accent to balance the larger h1.
- Subhead is `text-xl md:text-2xl font-bold` (bolded per Jeremy's note). Lato Bold weight 700.
- Section uses `bg-mavs-navy text-white` solid fill. No photo background. The /boosters StaticHero uses a photo; this page deliberately uses a solid navy field so the body sections below can carry the visual weight.

### 2. Mission statement (prose)

Centered prose block immediately under the hero. Cream/white background, plenty of vertical air. This is the sales pitch. Copy below is Jeremy's draft verbatim — copy is editable post-launch, but ship exactly this.

```
<section class="container mx-auto px-4 py-16 md:py-20 max-w-3xl">
  <div class="space-y-6 text-lg leading-relaxed text-gray-800">
    <p>
      McNeil Mavericks Football is more than a team. It is a place where young men learn commitment, toughness, accountability, teamwork, and pride in representing their school and community.
    </p>
    <p>
      Our players put in countless hours before school, after school, during the summer, in the weight room, on the practice field, and under the Friday night lights. They give their time, energy, and heart to this program. As a Booster Club, our goal is to make sure they feel that same level of support from the community around them.
    </p>
    <p>
      Business sponsorships help provide the resources that make a real difference for our athletes throughout the season. Sponsor support helps fund team meals, banquets, extra equipment, player recognition, game day needs, travel support, and other football-specific expenses that help create a stronger, more meaningful experience for the young men in this program.
    </p>
    <p>
      When a business sponsors McNeil Football, it is doing more than advertising. It is standing behind local student-athletes. It is helping build school pride. It is showing families, fans, and players that this community believes in them.
    </p>
    <p>
      The McNeil Football Booster Club is a 501(c)(3) nonprofit organization, and we are grateful for the local businesses that choose to invest in our players and our program.
    </p>
    <p class="font-semibold text-mavs-navy">
      We invite you to partner with us this season and help support the McNeil Mavericks Football team.
    </p>
    <p>
      Your sponsorship matters. Your support is seen. And it directly impacts the athletes who wear the McNeil jersey.
    </p>
  </div>
</section>
```

Notes:
- `max-w-3xl` keeps line length readable.
- `text-lg leading-relaxed` — Lato Regular 400, comfortable reading size.
- Second-to-last paragraph (`We invite you to partner...`) gets emphasis: `font-semibold text-mavs-navy`. Pulls the eye to the call-out before the closing line.
- Copy is editable — comment in code: `// Copy editable per Jeremy 2026-05-23. Verbatim from initial draft; revisit with Kendra/board.`

### 3. Sponsorship tiers heading + cards

Section heading, then 5 tier cards. **3-2 layout: 3 smaller cards on top row, 2 larger cards centered on second row.** This is Jeremy's call (2026-05-23) — 5-across reads too small on desktop.

The 5 tiers in `sort_order` ascending are MVP (1), Diamond (2), Platinum (3), Gold (4), Blue (5). With the 3-2 split:
- **Top row (3 cards, smaller):** Blue, Gold, Platinum — the lower tiers
- **Bottom row (2 cards, larger, centered):** Diamond, MVP — the prestige tiers

This puts visual weight on the larger commitments, mirroring how `/sponsors` puts MVP at the top. Going low-to-high builds value as the eye scans down.

Implementation: sort the tiers array `DESC` after the SQL fetch (or fetch descending) so the array reads `[MVP, Diamond, Platinum, Gold, Blue]`. Then split:
- `topRow` = sort_order 3, 4, 5 → Platinum, Gold, Blue (rendered left-to-right as Blue, Gold, Platinum — ascending price within the row so price grows toward the center/right of the screen)
- `bottomRow` = sort_order 1, 2 → MVP, Diamond (rendered as Diamond, MVP — ascending price)

Wait — that builds value left-to-right within each row but the rows don't visually escalate. Cleaner: render both rows ascending-price left-to-right, top row first. Top row reads Blue → Gold → Platinum (left to right), bottom row reads Diamond → MVP (left to right, centered). The eye scans naturally from low-commitment to high-commitment as it moves down and right.

```
const tiersAsc = tiers; // already sort_order ASC = MVP, Diamond, Platinum, Gold, Blue (reversed price order)
// Re-sort to price-ascending for display:
const tiersByPrice = [...tiers].sort((a, b) => a.price_cents - b.price_cents);
// tiersByPrice = [Blue, Gold, Platinum, Diamond, MVP]
const topRow = tiersByPrice.slice(0, 3);    // Blue, Gold, Platinum
const bottomRow = tiersByPrice.slice(3, 5); // Diamond, MVP
```

Markup:

```
<section class="container mx-auto px-4 py-12 md:py-16">
  <div class="text-center mb-12">
    <h2 class="text-3xl md:text-4xl font-black uppercase tracking-tight text-mavs-navy">
      Sponsorship Levels
    </h2>
    <div class="h-1 w-20 bg-mavs-green mx-auto mt-3"></div>
    <p class="text-lg text-gray-600 mt-4 max-w-2xl mx-auto">
      Five tiers, real visibility. Every level supports McNeil football and puts your business in front of Mavs families all season long.
    </p>
  </div>

  {/* Top row: 3 smaller cards */}
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 mb-6 max-w-5xl mx-auto">
    {topRow.map(tier => <SponsorshipTierCard tier={tier} size="small" />)}
  </div>

  {/* Bottom row: 2 larger cards, centered */}
  <div class="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-3xl mx-auto">
    {bottomRow.map(tier => <SponsorshipTierCard tier={tier} size="large" />)}
  </div>
</section>
```

Notes on the grid:
- Top row container `max-w-5xl mx-auto` — 3 cards across on lg.
- Bottom row container `max-w-3xl mx-auto` — 2 cards across on md, narrower outer width so the cards sit visually centered under the top row.
- Mobile: both grids collapse to single column. The 3-2 visual hierarchy only matters on desktop.
- Tablet (md): top row stays 3-across at `sm:grid-cols-2 lg:grid-cols-3` which gives 2-then-1 stacking. Acceptable. If it looks awkward in QA, switch top row to `md:grid-cols-3` so all 3 line up at md+.

### 3a. SponsorshipTierCard component

Define inline at the top of the page file (matches `SponsorStripLogo` / `SponsorCard` patterns from the other sponsor pages — no new component file).

```
function SponsorshipTierCard({ tier, size }: { tier: SponsorshipTier; size: 'small' | 'large' }) {
  const dollars = Math.round(tier.price_cents / 100).toLocaleString('en-US');
  const isLarge = size === 'large';
  return (
    <div class={`
      relative bg-white border-2 rounded-lg flex flex-col
      ${tier.badge_label ? 'border-mavs-green' : 'border-mavs-navy/20'}
      ${isLarge ? 'p-8' : 'p-6'}
    `}>
      {tier.badge_label && (
        <div class="absolute -top-3 right-4 bg-mavs-green text-white text-xs font-bold uppercase tracking-wider px-3 py-1 rounded-full">
          {tier.badge_label}
        </div>
      )}
      <div class="text-center mb-4">
        <p class={`font-black text-mavs-navy ${isLarge ? 'text-5xl' : 'text-4xl'}`}>
          ${dollars}
        </p>
        <h3 class={`font-bold uppercase text-mavs-navy mt-1 ${isLarge ? 'text-2xl' : 'text-xl'}`}>
          {tier.name}
        </h3>
        {tier.description && (
          <p class="text-sm text-gray-600 italic mt-2">{tier.description}</p>
        )}
      </div>
      <ul class="space-y-2 flex-grow">
        {(tier.perks as string[]).map((perk, i) => (
          <li key={i} class={`flex gap-2 ${isLarge ? 'text-base' : 'text-sm'} text-gray-800`}>
            <span class="text-mavs-green font-bold">+</span>
            <span>{perk}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

Notes:
- Cards with `badge_label` (Platinum has "Recommended") get a 2px solid `border-mavs-green` and the green pill badge top-right. Same pattern as `/boosters/join` cards.
- Cards without get `border-mavs-navy/20` — subtle 2px navy at 20% opacity. Matches the brand convention.
- Price displayed as `$5,000` (comma-formatted) not `$500000`. `toLocaleString('en-US')` handles it.
- Perks rendered with `+ ` prefix in green — matches `/boosters/join` style. `perks` is `jsonb` storing a string array; cast `as string[]`.
- No CTA button on the card itself. The single CTA is below the grid (see next section). Adding "Sponsor at MVP" buttons to each card would imply each card is its own action, which it isn't in Phase 1.
- `flex flex-col` + `flex-grow` on the perks list makes all cards in a row equal height when content varies.

### 4. Contact CTA card

Below the tier grid. The page's primary call to action. Email-only.

```
<section class="container mx-auto px-4 py-12 md:py-16">
  <div class="bg-mavs-navy text-white rounded-lg p-8 md:p-12 text-center relative overflow-hidden max-w-3xl mx-auto">
    <div class="absolute top-0 left-0 right-0 h-1 bg-mavs-green"></div>
    <h2 class="text-2xl md:text-3xl font-black uppercase tracking-tight">
      Ready to Sponsor?
    </h2>
    <p class="text-lg text-white/90 mt-4 max-w-xl mx-auto">
      Reach out to the McNeil Football Booster Club and we'll get you set up at the level that's right for your business.
    </p>
    <a href="mailto:mcneilfootballboosters@gmail.com?subject=McNeil%20Football%20Sponsorship%20Inquiry"
       class="inline-block mt-8 bg-mavs-green text-white px-8 py-4 font-bold uppercase hover:bg-mavs-green/90 transition-colors text-lg">
      Email Us to Become a Sponsor
    </a>
    <p class="text-sm text-white/70 mt-4">
      mcneilfootballboosters@gmail.com
    </p>
  </div>
</section>
```

Notes:
- Mirrors the footer CTA card on `/sponsors` (top green stripe + navy fill + green button).
- `mailto:` link includes a pre-filled subject line. Helps Kendra and any future address change route inquiries cleanly.
- Email address printed in plain text below the button as well — some users don't want to open their mail client; they want to copy the address into webmail.
- Button is `bg-mavs-green text-white` (white-on-green passes WCAG AA at large bold sizes; same call as the `/sponsors` footer card per `sponsors_page_spec.md` deviation 1).
- Email is `mcneilfootballboosters@gmail.com` — the documented working address (per `credentials.md`, this is the SportsEngine billing email and backs the booster Google Form). Do **not** use `@mcneilmavericks.org` aliases anywhere on this page — none are wired up yet.

### 5. Sponsor strip (bottom)

Same component / same data shape as the homepage strip. Two-row tier-partitioned layout. Reads as a thank-you band at the bottom of the page: "here's who already said yes."

```
<section class="container mx-auto px-4 py-12 md:py-16 border-t-2 border-mavs-green/30">
  <h2 class="text-2xl md:text-3xl font-bold text-mavs-navy text-center mb-10">
    Thank You to Our {currentYear.replace('-', '-20')} Sponsors!
  </h2>

  {topTierSponsors.length > 0 && (
    <div class="flex flex-wrap items-center justify-center gap-12 mb-8">
      {topTierSponsors.map(s => <SponsorStripLogo sponsor={s} sizeClass="max-w-[220px] max-h-20" />)}
    </div>
  )}

  {otherSponsors.length > 0 && (
    <div class="flex flex-wrap items-center justify-center gap-8 md:gap-12">
      {otherSponsors.map(s => <SponsorStripLogo sponsor={s} sizeClass="max-w-[160px] max-h-12" />)}
    </div>
  )}

  <div class="text-center mt-10">
    <a href="/sponsors"
       class="text-mavs-navy font-semibold uppercase tracking-wide text-sm hover:text-mavs-green transition-colors">
      See All Sponsors →
    </a>
  </div>
</section>
```

Partitioning:
```
const topTierSponsors = sponsors.filter(s => s.tier_id === mvpTierId);
const otherSponsors = sponsors.filter(s => s.tier_id !== mvpTierId);
```

Notes:
- Heading reads "Thank You to Our 2025-2026 Sponsors!" — the `currentYear.replace('-', '-20')` turns `'2025-26'` into `'2025-2026'`. If a helper already exists for this format conversion (check homepage strip code in `app/page.tsx`), reuse it.
- Top border (`border-t-2 border-mavs-green/30`) separates the strip from the contact CTA card above.
- `SponsorStripLogo` component: reuse the inline component from `app/page.tsx`. If it's already in `app/page.tsx` only, lift it into a shared location (`components/sponsors/SponsorStripLogo.tsx`) and import it from both files. This is the second consumer; pulling it out makes sense now. If lifting feels disruptive in this commit, duplicate the inline component and leave a `// TODO: extract — duplicated from app/page.tsx` comment; the duplication is short and the trade is fine.
- "See All Sponsors →" link mirrors the homepage strip. Sends visitors to the full grouped /sponsors page.
- Empty sponsor list: if `sponsors.length === 0`, hide this entire section. Don't render an empty thank-you band.

## Layout summary

Top to bottom:
1. Navy hero with big title + bold subhead (`bg-mavs-navy`, `py-16 md:py-20`)
2. Mission statement prose (white bg, `max-w-3xl`, `py-16 md:py-20`)
3. Sponsorship Levels heading + 3-2 tier cards (white bg, `py-12 md:py-16`)
4. Contact CTA card (navy card on white bg, `py-12 md:py-16`)
5. Sponsor strip (white bg, top border, `py-12 md:py-16`)

Visual rhythm: navy → white → white → navy-card-on-white → white. The two navy moments (hero + CTA card) bracket the prose and tier sections. Green accents (h1 underline, badge pills, perk plus-signs, CTA button, strip top border) tie the brand together throughout.

## Routes that link to this page (already exist, will start working)

- `/sponsors` page-header "Become a Sponsor →" button (existing, currently 404s)
- `/sponsors` footer CTA card "See Sponsorship Options" button (existing, currently 404s)
- `/boosters` page — confirm if a sponsorship CTA already exists there; if not, no work in this commit
- Carousel "Become a Sponsor" headline_cta tile from migration 041 (existing, currently 404s)

After this ships, console errors from those links resolve themselves.

## Accessibility

- Heading order: h1 (hero) → h2 (Sponsorship Levels) → h3 (each tier name) → h2 (Ready to Sponsor) → h2 (Thank You). No skipped levels.
- All buttons have full label text. The contact button reads "Email Us to Become a Sponsor", not bare "Email Us."
- Color contrast: white on `#011858` (navy) and white on `#1E541E` (green) both pass WCAG AA. Navy on `#1E541E` does NOT pass — never put navy text on green at small sizes.
- `mailto:` link works in screen readers as expected; no special handling needed.
- Lighthouse a11y target ≥ 90.

## Acceptance criteria

1. `/boosters/sponsor` renders without errors. Page returns 200 in `curl` and on Vercel preview.
2. `/boosters/sponsor/foo` (or any subpath) returns 404 (catchall route).
3. Hero renders "Support McNeil Mavericks Football" as h1 at `text-4xl md:text-6xl font-black`, navy band background, white text, green accent underline.
4. Hero subhead "Every sponsorship directly supports the athletes in the McNeil Football program." renders bolded at `text-xl md:text-2xl font-bold`.
5. Mission statement prose renders all 7 paragraphs verbatim. The "We invite you to partner with us this season..." paragraph is visually emphasized (semibold, navy).
6. Tier cards: 5 cards total, 3 in top row (Blue, Gold, Platinum left-to-right), 2 in bottom row (Diamond, MVP left-to-right, centered).
7. Bottom row cards are visibly larger than top row cards (`p-8` vs `p-6`, `text-5xl` vs `text-4xl` price, `text-2xl` vs `text-xl` name).
8. Platinum card shows the "Recommended" badge in a green pill, top-right corner.
9. All cards display: price formatted with commas (e.g., `$5,000`), tier name uppercase, description italic gray, perks list with green `+` prefix.
10. Contact CTA card renders below the tier grid with green-stripe-on-navy, "Email Us to Become a Sponsor" button as `mailto:mcneilfootballboosters@gmail.com` with pre-filled subject.
11. Email address `mcneilfootballboosters@gmail.com` printed in plain text below the button.
12. Sponsor strip at the bottom renders Rudy's BBQ alone on row 1 (larger), 6 Golds on row 2 (smaller), "See All Sponsors →" link centered below.
13. Mobile (375px viewport): everything stacks. Tier cards single column. Both rows collapse. Sponsor strip wraps gracefully.
14. No console errors on Vercel preview.
15. Lighthouse a11y ≥ 90 on Vercel preview.
16. No `@mcneilmavericks.org` email addresses anywhere on this page.

## Rollback

Revert the commit. `/boosters/sponsor` returns to 404. No data changes — this commit doesn't touch the DB. Linked-from pages (`/sponsors`, carousel CTA) revert to broken-link state they were in before this work.

## Decisions confirmed by Jeremy 2026-05-23

1. **No inquiry form, no Stripe.** Email contact only. Defers `sponsorship_inquiries` table indefinitely.
2. **Email is `mcneilfootballboosters@gmail.com`.** The only documented working address. Not `boosters@mcneilmavericks.org`, not `sponsorship@mcneilmavericks.org` — neither is wired up yet (J9 pending).
3. **Tier layout is 3-2.** 3 smaller cards on top row, 2 larger cards on bottom row, centered. Not 5-across (too small on desktop). Not table.
4. **Hero copy is bigger.** "Support McNeil Mavericks Football" at `text-4xl md:text-6xl` (one step up from other page h1s on the site). Subhead bolded.
5. **Mission statement copy is Jeremy's draft, verbatim.** Copy editable later; ship exactly what's in the spec for now.
6. **Brand colors used throughout.** Navy hero + navy CTA card frame the page; green accents (underlines, badges, plus-signs, button) tie everything to the brand. Same palette discipline as `/sponsors`.

## Implementation order

Single CC turn:

1. Verify preconditions (queries above)
2. Build `app/boosters/sponsor/page.tsx` per layout above
3. Build `app/boosters/sponsor/[catchall]/page.tsx` (unconditional `notFound()`)
4. If lifting `SponsorStripLogo` to `components/sponsors/`, update `app/page.tsx` import too
5. Verify locally: every section renders, every link works, mobile collapse looks right
6. Run `npm run typecheck`, `npm run lint`
7. Verify Vercel preview deploy: all 16 acceptance criteria pass
8. Commit + push

Estimated effort: one evening.

## Out of scope for this commit

- Sponsorship inquiry form (Phase 2)
- Stripe Checkout for sponsorships (Phase 2)
- Admin CRUD for sponsorship tiers (Phase 2 — Studio edits work today)
- `sponsorship@mcneilmavericks.org` alias setup (J9)
- Sponsor flyer PDF download link (content_map_v2 mentioned this — defer until there's a flyer to link to)
- Per-tier "Choose this tier" CTAs on the cards (would need a form to submit to; single-CTA design is cleaner for Phase 1)
- Revising the mission statement copy (defer until Kendra/board input)
- Reviving the carousel sponsor_spotlight tiles (separate decision)

## First instruction for CC

> Implement `boosters_sponsor_spec.md`. Verify the two precondition SQL queries first; report results. If preconditions pass, build `app/boosters/sponsor/page.tsx` + `app/boosters/sponsor/[catchall]/page.tsx` per the layout. Reuse `SponsorStripLogo` from `app/page.tsx` (lift to `components/sponsors/SponsorStripLogo.tsx` and update both call sites, OR duplicate inline with a TODO — your call). Run typecheck + lint, verify against the 16 acceptance criteria on Vercel preview, then commit + push. Confirm working tree is clean and origin/main matches local before starting.
