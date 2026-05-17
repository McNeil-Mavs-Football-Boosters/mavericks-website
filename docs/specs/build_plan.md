# Phase 1 Build Plan

Written 2026-05-15. Reads with `CLAUDE.md`, `spec_review.md`, `content_map.md`, `admin_scope.md`, `schema.md`.

Two parallel tracks. Jeremy runs Track A (accounts, board, content gathering). CC runs Track B (code). Track B can start once Track A item J1 is done; the rest of Track A overlaps.

## Hard dates

These are the only fixed anchors. Everything else is "as fast as we can."

| Date | Event | What it gates |
|---|---|---|
| **Mon 2026-06-02** | Board meeting #1 (Tuesday Jun 2 = first Tuesday of June; per `booster_club_info.md` cadence). Confirm date with Carol. | Demo staging site to board, gather feedback. Soft gate. |
| **Tue 2026-07-07** | Board meeting #2 (first Tuesday of July). | Final board sign-off on cutover. Hard gate before flipping DNS. |
| **Mon 2026-07-13** | Target cutover window opens. | Earliest acceptable DNS flip. Gives 18 days of buffer to SE lapse. |
| **Mon 2026-07-20** | Target cutover window closes. | Latest acceptable DNS flip for an unhurried cutover. |
| **Wed 2026-07-29** | Last day to cancel SE for July 31 renewal lapse. | If we don't cancel here, SE bills another $1,385. |
| **Fri 2026-07-31** | SE subscription lapses. | After this, SE rollback is gone. |

The plan targets July 13-20 cutover, treats July 7 board meeting as final sign-off, and treats July 29 as the hard "must have shipped or cancel" date.

## Track A — Jeremy (parallel, non-blocking after J1)

These can happen in any order except as noted.

**J1. GitHub organization + empty repo.** Create org "mcneil-mavericks-boosters" (or similar). Add Jeremy as owner, son as member. Create empty repo `mavericks-website`. This is the only Track A item that blocks Track B. Should take 10 minutes.

**J2. Vercel account.** Sign up with GitHub. Link the org. Hobby tier is free and fine for Phase 1. Confirm: deploys auto-trigger from `main` branch.

**J3. Supabase project.** Sign up. Create project named "mavericks-website". US region. Capture: project URL, anon key, service role key. These become env vars; do not commit them. Share with CC via 1Password or `.env.local` (not in repo).

**J4. 1Password Families shared vault.** Recommended, not required. Create "Booster Club" vault. Add Carol or Ashley as a second owner. Move the credentials inventory from `credentials.md` into vault items as you gain access to each. ~$60/yr split across officers.

**J5. Google Workspace for Nonprofits — DEFERRED.** Per `credentials.md`, Phase 1 uses Cloudflare Email Routing forwarders only. No real mailboxes. Officers receive role-addressed mail in their personal Gmail; replies originate from personal addresses unless someone configures Gmail "Send mail as" later. Revisit only if an officer needs to send mail as a role address from a real inbox. No action required for cutover.

**J6. Stripe account.** Create account, business type = nonprofit, EIN 26-4231242. Apply for Stripe nonprofit pricing during signup. Add booster bank account once it exists; until then, test mode works without it. Capture: test publishable key, test secret key, webhook signing secret. These become env vars.

**J7. Booster bank account confirmation.** Talk to Chevon. Required for Stripe to actually deposit money. Until this is done we can ship the whole site in Stripe test mode and only flip to live mode at the last minute. Bank account itself is the open item from `next_steps.md` item 6.

**J8. IRS determination letter + bylaws PDFs.** From Chevon. Needed for: Google Workspace for Nonprofits, Stripe nonprofit pricing, and the `/documents` page. Two PDFs total.

**J9. Cloudflare account.** Free tier. Add `mcneilmavericks.org` as a site (Cloudflare gives you the two nameservers you'll point at). Configure DNS records mirroring what SE has today, except A/CNAME records for the apex and `www` point at Vercel. Do NOT change nameservers at Network Solutions yet; just stage Cloudflare's config. Set up Cloudflare Email Routing with the alias list from `content_map.md` site_settings forwarding to officers' personal addresses (per `next_steps.md` item 3a).

**J10. Content gathering during meetings.** At June 2 and July 7 meetings:
- Membership tier perks (board ratifies the placeholders)
- Sponsorship tier perks (Kendra refines what McNeil can actually deliver)
- "What dues fund" copy from Chevon
- Logo authorization status from Sylvia (school logos OK to use? if not, ship type-only)
- Mailing address final answer
- Confirm `/members` page heading: "thank you to our supporters" vs "dues-paid members"

None of this blocks code. All of it ships as admin-editable content.

## Track B — CC (sequential)

Each step has prerequisites, acceptance, and rollback. Steps don't have deadlines individually; they have a flow. The whole track needs to complete the work in Steps 1-15 before the July 7 board meeting and Steps 16-20 before July 20.

If you blow through these in two weekends instead of nine, great. The plan accommodates that.

---

### Step 1. Scaffold

**Prereqs:** J1 done. (CC can scaffold locally without J1 and push later if needed.)

**Deliverable:** Next.js 15 (App Router) + TypeScript (strict) + Tailwind + shadcn/ui repo. Folder structure for `app/`, `app/(public)/`, `app/(admin)/`, `app/api/`, `components/`, `components/ui/` (shadcn), `lib/`, `lib/supabase/`, `db/migrations/`, `db/seed/`. ESLint + Prettier configured. `README.md` documenting setup. `.env.example` listing every env var (Supabase, Stripe). `.gitignore` covering `.env*` and `.next`.

**Acceptance:** `pnpm dev` (or `npm run dev`) renders a placeholder page locally. Deploys cleanly to Vercel from `main` via GitHub.

**Rollback:** None needed. The site isn't live anywhere except a vercel.app URL no one knows.

---

### Step 2. Supabase wiring

**Prereqs:** Step 1, J3.

**Deliverable:** `@supabase/supabase-js` installed. `lib/supabase/server.ts` (server client with service role for API routes), `lib/supabase/client.ts` (browser client with anon key). Env vars wired in Vercel. A smoke-test page (e.g., `/dev/ping`) that fetches `now()` from Postgres and renders it. Remove the smoke-test page before Step 4.

**Acceptance:** Smoke-test page deployed shows current Postgres time. Confirms server-side reads work and env vars are correctly set in Vercel.

**Rollback:** Revert commit. Nothing in DB yet.

---

### Step 3. Apply schema

**Prereqs:** Step 2.

**Deliverable:** Split `schema.md` SQL into ordered migration files in `db/migrations/`:
1. `001_extensions_and_types.sql` (pgcrypto if needed, all CREATE TYPE)
2. `002_auth_and_roles.sql` (user_roles + helper function)
3. `003_content_tables.sql` (news through documents)
4. `004_transactional_tables.sql` (payments, then memberships, then ALTER sponsors)
5. `005_settings.sql` (site_settings)
6. `006_triggers.sql` (touch_updated_at + validate_membership_paid_state)
7. `007_views.sql` (public_members)
8. `008_rls.sql` (all RLS policies)
9. `009_storage_policies.sql` (storage.objects policies)
10. `010_seed.sql` (membership tiers, sponsorship tiers, board, committees)

Storage buckets created via Supabase Studio (manual, documented in README).

**Acceptance:** All 14 tables visible in Supabase Studio. RLS enabled on every table. Anon SELECT works against `membership_tiers` and returns 6 rows. Anon SELECT against `memberships` returns nothing (or errors). Storage buckets exist with correct policies.

**Rollback:** `DROP SCHEMA public CASCADE; CREATE SCHEMA public;` then re-run migrations. Free to do this until production goes live.

---

### Step 4. Public layout + static routes

**Prereqs:** Step 3.

**Deliverable:** `Layout`, `Header`, `Footer` components. RRISD disclaimer in footer (pulled from `site_settings`). Five static routes: `/`, `/about`, `/contact`, `/privacy`, `/404`. Home pulls hero from settings. About pulls mission and board (board can be empty array until seed runs — already seeded). Contact is a form posting to `/api/contact` (sends email via Resend or stubs an `INSERT` for Phase 1; Resend can wait). Privacy is MDX in repo.

**Acceptance:** All five routes render. Visually presentable on mobile and desktop. Footer disclaimer matches `site_settings.school_affiliation_disclaimer`.

**Rollback:** Trivial. Nothing is linked from anywhere external.

---

### Step 5. Public collection routes

**Prereqs:** Step 4.

**Deliverable:** `/news`, `/news/[slug]`, `/events`, `/events/[slug]`, `/sponsors`, `/board`, `/documents`, `/members`, `/get-involved`. All read-only, pulling from RLS-public views/tables. Empty states designed (no "No items found" boxes; hide empty sections instead, per `content_map.md`). `/members` queries `public_members` view. `/get-involved` shows seed committees.

**Acceptance:** All routes render with seed data. Test by visiting them in an incognito window (proves anon RLS works). No console errors.

**Rollback:** Trivial.

---

### Step 6. Admin auth

**Prereqs:** Step 5.

**Deliverable:** `/admin/login` route. Supabase Auth email/password sign-in. `/admin/*` protected via Next middleware that checks session and role. Login redirect logic. Sign-out button. `app/(admin)/layout.tsx` with admin shell (sidebar nav, role badge).

Seed Jeremy as the first super_admin: insert into `auth.users` via Supabase Studio (create the account first), then insert into `user_roles` with role = `super_admin`. This is a one-time manual step documented in README.

**Acceptance:** Jeremy can sign in at `/admin/login`, lands on `/admin`, sees admin shell. Non-authenticated visit to `/admin/*` redirects to login. Authenticated but non-admin user (test with a second account in `auth.users` without a role) gets a "not authorized" page.

**Rollback:** Revert. `auth.users` rows can stay; they don't expose anything without a role.

---

### Step 7. Admin CRUD — Tier A1 (news, events, site settings)

**Prereqs:** Step 6.

**Deliverable:**
- `/admin/news` (list, create, edit, draft/publish toggle, delete with confirm)
- `/admin/events` (list, create, edit, mark cancelled, delete)
- `/admin/settings` (single-page form for the `site_settings` singleton)

TipTap as the rich text editor (recommended over Lexical for maturity and simplicity; flag if you want to reconsider). Image upload to Supabase Storage `news-images` and `event-images` buckets. Inline image insertion in TipTap.

**Acceptance:** Jeremy creates a news post in admin, sees it on `/news`. Marks it draft, no longer visible on public site. Creates an event with cover image, sees it on `/events`. Edits hero headline in settings, sees the change on `/` immediately.

**Rollback:** Revert. Content rows can stay; nothing public-facing is broken.

---

### Step 8. Admin CRUD — Tier A2 (tier configs)

**Prereqs:** Step 7.

**Deliverable:**
- `/admin/membership-tiers` (list, create, edit, drag-to-reorder, soft-archive)
- `/admin/sponsorship-tiers` (same)

Forms include perks-as-array editor (one row per perk, add/remove). `requires_tshirt_size` and `badge_label` editable.

**Acceptance:** Jeremy renames "Game Day!" to "Maverick Fan" and changes price, sees the update on `/join` and on the homepage CTA card if applicable.

**Rollback:** Revert. Tier rows can stay; only naming/price changes get lost.

---

### Step 9. Stripe — membership flow (test mode)

**Prereqs:** Step 8, J6 (Stripe test keys).

**Deliverable:**
- `/join` form with all fields from `content_map.md` Join page detail
- Conditional fields (t-shirt size based on tier)
- Public listing opt-in checkbox
- `/api/memberships/create` endpoint (server-side, service role): validates input, creates `memberships` row with `paid=false`, either redirects to Stripe Checkout (paid tiers) or completes immediately ($0 Free Fan Base)
- `/api/stripe/webhook` handler: verifies signature, handles `checkout.session.completed`, upserts `payments` row with idempotency (`ON CONFLICT (stripe_session_id)`), flips `memberships.paid = true` and links `payment_id`
- Success page at `/join/thanks?session_id={CHECKOUT_SESSION_ID}` (Stripe redirects here)
- Failure/cancel page at `/join/cancelled`

**Acceptance:**
- Submit form with Free Fan Base tier → row created, `paid=true`, no Stripe call
- Submit form with Game Day tier → redirected to Stripe Checkout (test mode) → use card `4242 4242 4242 4242` → webhook fires → `memberships.paid=true`, `payment_id` populated, `payments.status='succeeded'`
- Replay the same webhook event twice → only one `payments` row, no duplicate, no state corruption
- Try submitting `paid=true` directly to the create endpoint (curl) → fails or is forced to `paid=false`

**Rollback:** Feature-flag the `/join` form back to "Coming soon — sign up via [Google Form URL]." Schema and unused API code stay. Test memberships rows can be soft-deleted.

---

### Step 10. Stripe — donation flow (test mode)

**Prereqs:** Step 9.

**Deliverable:** `/join#donate` anchor or `/donate` route with preset amounts ($25, $50, $100, $250, $500) and custom amount field. Reuses the same `/api/stripe/webhook` handler with `purpose='donation'`. Donor email + name captured at Stripe Checkout, written to `payments` table.

**Acceptance:** Test donation of $50 creates a `payments` row, `purpose='donation'`, `payer_email` and `payer_name` populated, no `memberships` row.

**Rollback:** Hide the donation entry point. Schema unchanged.

---

### Step 11. Admin CRUD — memberships

**Prereqs:** Step 9.

**Deliverable:**
- `/admin/memberships` (list, filter by year and tier and paid status, edit any field, manual mark-paid, soft-delete with un-delete, CSV export)
- Manual mark-paid flow: when admin toggles `paid=true` and there's no `payment_id`, prompt to record a manual payment (method = `cash` | `check` | `other`, notes field) which creates a `payments` row and links it
- Error handling: catch the `validate_membership_paid_state` exception and surface as "Cannot mark this membership as paid without recording a payment first."
- Default list filter: `year = '2026-27'`, no `active` filter (trash-can pattern)

**Acceptance:** Jeremy:
- Adds a manual cash membership for a parent who paid at a meeting
- Edits a typo in a parent email
- Soft-deletes a duplicate signup; sees it greyed-out in the list; un-deletes it
- Exports the year's signups to CSV

**Rollback:** Revert. No public-facing impact.

---

### Step 12. Migrate the 35 existing signups

**Prereqs:** Step 11, Jeremy exports the 2026-27 Google Form to CSV.

**Deliverable:** One-time script at `scripts/migrate_2026_27.ts`. Reads CSV, maps columns to `memberships` per `schema.md` migration plan. For the 7 paid rows, creates `payments` with `method='other'` and a descriptive `notes` field. Leaves the 28 unpaid as `paid=false`, `payment_id=null`. Idempotent (re-running doesn't duplicate; matches on parent_1_email + year).

**Acceptance:**
- `/admin/memberships` filtered to `year = '2026-27'` shows 35 rows
- 7 rows show `paid=true` and have linked `payments` rows with `method='other'`
- `/members` public page shows the subset who had `list_publicly=true` on the form
- Re-running the script does not create duplicates

**Rollback:** `DELETE FROM payments WHERE notes LIKE '%migrated%'; DELETE FROM memberships WHERE created_at < <migration_timestamp> AND year = '2026-27';` Re-run script after fix.

After this lands, Jeremy sends re-invoice emails (or a board member does) to the 8 "email-sent" parents pointing at the new Stripe-backed `/join` URL. Not a CC task.

---

### Step 13. Admin CRUD — Tier B

**Prereqs:** Step 11.

**Deliverable:**
- `/admin/sponsors` (CRUD + logo upload to `sponsor-logos`)
- `/admin/board` (CRUD + photo upload to `board-photos`, year filter for historical boards)
- `/admin/documents` (CRUD + PDF upload to `documents` bucket, type tagging)
- `/admin/volunteer-opportunities` (CRUD)
- `/admin/committees` (CRUD)

All reuse the patterns from Step 7. No new architecture.

**Acceptance:** Each admin route lists, creates, edits, and (where applicable) uploads files. Each maps to its public route correctly.

**Rollback:** Revert per content type if any one is half-baked at cutover.

---

### Step 14. Hardening

**Prereqs:** Step 13.

**Deliverable:**
- Form validation messages in plain English (per `admin_scope.md` editor UX requirement 7)
- 404 page with helpful links
- Mobile responsive pass (test at 375px, 768px, 1280px widths)
- Keyboard navigation works on every page
- Lighthouse a11y ≥ 90 on `/`, `/about`, `/join`, `/sponsor`, `/news/[slug]`
- SEO basics: meta tags, Open Graph image, `sitemap.xml`, `robots.txt`
- Error boundary on `app/error.tsx` and `app/global-error.tsx`
- A "site is in beta" banner toggle in `site_settings` for the staging period (optional)

**Acceptance:** Lighthouse a11y ≥ 90 on listed routes. Manual mobile pass on iPhone-sized viewport. Sitemap generated.

**Rollback:** None needed.

---

### Step 15. Stripe live mode

**Prereqs:** Step 14, J6 + J7 done (Stripe account funded with bank account).

**Deliverable:** Live Stripe keys in Vercel production env (separate from preview/dev). Webhook endpoint in Stripe dashboard pointed at `https://<preview-url>/api/stripe/webhook` initially, then swapped to the real domain at Step 18. Smoke test: real $1 charge from Jeremy's card, full webhook → payment row → membership flip.

If Stripe nonprofit pricing was approved (J6), confirm it's applied. If not, proceed with standard pricing; can update later.

**Acceptance:** Real $1 transaction succeeds end-to-end. Stripe dashboard shows the payment. Treasurer (Chevon) granted readonly_admin access can see the row in `/admin/payments`.

**Rollback:** Swap env vars back to test keys; the $1 charge can be refunded from Stripe dashboard.

---

### Step 16. Board walkthrough

**Prereqs:** Step 15. Date: **July 7 board meeting**.

**Deliverable:** Live demo on staging URL (vercel.app subdomain or `mcneilmavericks.com` if you choose to use it as the staging URL via the existing Network Solutions WebForwarder). Walk officers through: making a news post, editing tier prices, viewing the payments dashboard. Have each officer log in once at the meeting and edit one thing (per `admin_scope.md` "ceremonial" mitigation).

**Acceptance:** Board votes to proceed with cutover in the July 13-20 window. Any blocking feedback gets logged.

**Rollback:** Defer cutover by one cycle; SE keeps running. If board says no in early July, cancel cutover entirely and reassess (this is the last reversible point before money is on the line for SE renewal).

---

### Step 17. Pre-cutover prep

**Prereqs:** Step 16. Do this 48-72 hours before the chosen cutover day.

**Deliverable:**
- Add `mcneilmavericks.org` as a custom domain on the Vercel project (don't change DNS yet; Vercel will say "Invalid Configuration" until DNS flips — that's fine)
- Verify Cloudflare zone (J9) has all the right records: A/AAAA pointing at Vercel, MX records for Cloudflare Email Routing, TXT for SPF/DKIM/DMARC (Cloudflare auto-generates SPF for Email Routing; add Resend's DKIM record once Resend is wired up), CAA
- Lower DNS TTL at the current authoritative (SE nameservers) to 300 seconds. This may require asking SE support since DNS Made Easy is upstream. If not possible, accept that the cutover will take up to current TTL to fully propagate (likely 1-4 hours).
- Final content review: news, events, board, sponsors all show real data or hide gracefully
- Final test of the Stripe webhook endpoint URL — it'll need to be updated to the production domain post-flip
- Brief Carol and Chevon: "DNS flips on <date>; if anything breaks, contact me; SE rollback available for 7 days"

**Acceptance:** All the above done; nothing actually changed at the registrar yet.

**Rollback:** Nothing to roll back. We haven't flipped.

---

### Step 18. Cutover

**Prereqs:** Step 17. Target: **Monday July 13 - Monday July 20**.

**Deliverable:** At Network Solutions, change nameservers on `mcneilmavericks.org` from `ns1-5.sportnginserver.com` to the two Cloudflare nameservers from J9. Save.

Within minutes: Cloudflare starts serving DNS. Within minutes-to-hours (depends on TTL of recursive resolvers globally): the rest of the internet sees the new records. Vercel issues SSL via Let's Encrypt automatically once it can verify ownership. Stripe webhook endpoint URL updated in Stripe dashboard to the production domain.

Verification checklist immediately after flip:
- `dig mcneilmavericks.org @1.1.1.1` shows Cloudflare nameservers
- `https://mcneilmavericks.org` loads the new site with valid SSL
- `https://www.mcneilmavericks.org` redirects to apex (or vice versa per Cloudflare config)
- Real test signup with Free Fan Base tier: row in DB
- Real test signup with Game Day tier ($20): Stripe charges, webhook fires, row paid
- Send a test email to `boosters@mcneilmavericks.org` from a personal address: arrives at the configured forwarding target
- News post visible on `/news`
- Mobile view loads cleanly

Optionally: set `mcneilmavericks.com` to redirect to `mcneilmavericks.org` (the existing Network Solutions WebForwarder already does this; just confirm it still resolves correctly).

**Acceptance:** All verification items pass.

**Rollback (the critical one):** At Network Solutions, change nameservers back to `ns1.sportnginserver.com` through `ns5.sportnginserver.com`. SE site resumes serving once DNS propagates. The new site is still deployed on Vercel and reachable via the vercel.app URL; only the custom-domain attachment is broken. Total rollback time: under 30 minutes plus DNS TTL.

---

### Step 19. Post-cutover monitoring

**Prereqs:** Step 18. Duration: 7 days.

**Deliverable:** Daily checks. Vercel logs for 500s and 404s. Supabase logs for query errors. Stripe dashboard for failed payments. Manual outreach to the first 3-5 real signups: "did the form work for you?" Track issues in a simple GitHub issues list.

**Acceptance:** No P0 bugs after 7 days. P1 bugs documented and triaged.

**Rollback:** Still available until SE lapses. After Day 7 of stability, the practical answer is "rollback is impossible" — and that's a good thing; it means we committed.

---

### Step 20. SE termination

**Prereqs:** Step 19 stable. Date: by **2026-07-29** (Wednesday before the July 31 renewal).

**Deliverable:** Cancel SE subscription via SE billing settings. Screenshot the confirmation. File in shared 1Password vault as evidence. Update `credentials.md` to remove SE from the active inventory.

**Acceptance:** No SE renewal invoice on August 1.

**Rollback:** None. This is irreversible. Make sure Step 19 was solid.

---

## Open decisions before CC starts

1. **Rich text editor** — TipTap (my pick) or Lexical. TipTap is simpler; Lexical is more powerful but heavier.
2. **Staging URL strategy during build** — use a Vercel-generated subdomain like `mavericks-website.vercel.app`, OR point the unused `mcneilmavericks.com` (Network Solutions WebForwarder, currently → `.org`) at Vercel during the build period for a friendlier staging URL. Option 2 doubles as a soft launch for sponsors/board to bookmark. My pick: option 2 if you want board members to remember the URL; option 1 if you don't.
3. **When to invite Carol/Ashley/Chevon to log in to admin** — at the July 7 demo (recommended; one-time ceremony) or earlier as they're available. Earlier feels safer to me; spreads the "wait, I can't log in" debugging.

DNS provider decision (Cloudflare) and email strategy (forwarders-only via Cloudflare Email Routing) are already settled in `credentials.md` and `next_steps.md` item 3a.

## First instruction for CC

Once J1 (GitHub repo) is ready, the first CC instruction is:

> Scaffold Step 1 of `build_plan.md`. Create the Next.js 15 + TypeScript + Tailwind + shadcn/ui repo with the folder structure listed. Set up ESLint, Prettier, and TypeScript strict mode. Initialize shadcn/ui with the default theme. Create `.env.example` listing every env var we'll need across all 20 steps (Supabase URL, anon key, service role key, Stripe publishable, Stripe secret, Stripe webhook secret, Resend API key for later). Create `README.md` with: stack overview, local setup commands, env var setup instructions, and a link back to `build_plan.md`. Commit to `main` and push. Confirm Vercel auto-deploy works. Stop and report the vercel.app URL.

If J1 isn't done yet, swap the first sentence to: "Scaffold Step 1 of `build_plan.md` in a local directory. Skip the GitHub push for now; report when the local dev server is running."
