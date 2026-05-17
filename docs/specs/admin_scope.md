# Admin Scope Decision Doc

Phase 1 admin scope for mcneilmavericks.org. Written 2026-05-14.

**Governing rule:** Anything a board member needs to change must be editable through a web admin UI by someone who has never written code. Board edits content; webmaster edits structure.

**Implication:** Content-as-code (MDX in repo) is OFF the table for anything board members touch. Almost everything in `content_map.md` becomes admin CRUD. The exceptions are listed at the bottom.

---

## Per-content-type decisions

For each content type, the question is: who edits it, how often, and does that person know what a Git repo is.

| Content type | Frequency of change | Who edits | Decision | Reasoning |
|---|---|---|---|---|
| **News posts** | Weekly during season | Secretary (Jeremy now, future secretaries vary) | **Admin CRUD with rich text editor** | Highest-frequency content. Has to be drop-dead easy. |
| **Events** | Weekly during season | Secretary + VP Social Events | **Admin CRUD** | Same logic as news. Calendar mode optional but not required Phase 1. |
| **Sponsors** | As Kendra closes deals (5-20/year) | VP Fundraising | **Admin CRUD with logo upload** | Logo upload required. Can't expect Kendra to commit images to a repo. |
| **Board roster (incl. photos)** | Yearly + mid-year corrections | President or Secretary | **Admin CRUD with photo upload** | Annual handoff is exactly when next year's board needs to update this. Photos are a sub-field, not a separate type. |
| **Documents (PDFs)** | Monthly (minutes) + rare (bylaws, IRS letter) | Secretary | **Admin CRUD with file upload** | Meeting minutes especially — monthly cadence. Has to be a paste-and-click. |
| **Volunteer opportunities** | Seasonally | VP Social Events / Secretary | **Admin CRUD** | Reasonable to expect a board member to add "Spirit Shack Friday Nights" without help. |
| **Committees** | Yearly (chair changes); rare (descriptions) | Secretary or President | **Admin CRUD** | Seeded with the 11 committees from the old SE site. Chair assignments updated yearly. |
| **Membership tiers** | Yearly | Treasurer + Board | **Admin CRUD** (configured as data, not code) | Confirmed: "Tier prices need to be easy to change." |
| **Sponsorship tiers** | Yearly | VP Fundraising + Board | **Admin CRUD** | Same logic. Confirmed at start of every fundraising cycle. |
| **Memberships (signup records)** | Continuous during signup season | Secretary or Treasurer | **Admin CRUD with manual paid override** | Migrating existing 35 signups. Need ability to mark cash/check as paid, edit records, soft-delete duplicates. |
| **Homepage settings (hero + CTA + image)** | Seasonally | Secretary or President | **Admin (settings page)** | Lets the board push a different primary CTA depending on what the club's pushing (membership in Aug, donations in Dec, sponsorship in summer). Hero image is a sub-field. |
| **About page copy (mission, what-dues-fund)** | Rarely (yearly?) | President | **Admin (page-block editor)** | Could be MDX, but then a President-only edit needs the webmaster. Easier path: rich text block editable in admin. |
| **Site settings (address, contact email, social links, EIN, etc.)** | Rare | Webmaster or President | **Admin (settings page)** | Includes things like the Facebook group URL — when SportsYou link changes, board can update without a deploy. |
| **Email aliases displayed on Contact page** | As role-based aliases are created | Webmaster | **Admin (settings)** | Just a display string, not the actual mail server config. |

**That's 14 admin-editable content types** (deduped from earlier draft that double-counted board photos and hero image). Big surface area. Let's talk about what we can cut without losing the principle.

---

## Phase 1 admin scope, in priority order

If we run out of time, cut from the bottom up. Top items are non-negotiable for cutover.

### Tier A — must ship for cutover (kill switch on SE)

1. **Authentication** — admins log in via Supabase Auth. Email + password. Future: magic links. No social login.
2. **News CRUD** — list, create, edit (rich text), publish/unpublish, delete, image upload inline.
3. **Events CRUD** — list, create, edit, mark cancelled, delete.
4. **Site settings page** — hero image, hero text, primary CTA, contact info, social links, EIN, mailing address, school affiliation disclaimer.
5. **Membership tiers CRUD** — list, create, edit, reorder, activate/deactivate.
6. **Sponsorship tiers CRUD** — same.
7. **Stripe Checkout integration** — guest checkout, dynamic line items pulled from tier configs. Webhook handler to record payments in DB. **$0 tier bypass:** Free Fan Base ($0) skips Stripe entirely; form submits directly with `paid=true`, `payment_id=null`.
8. **One-time donation flow** — Stripe Checkout with preset amounts ($25/$50/$100/$250/$500) + custom amount field.
9. **Membership signup form + admin CRUD** — public form on `/join` writes to `memberships` table. Admin can view list, filter by year/tier/paid-status, edit any record, manually mark paid (for cash/check), soft-delete, export to CSV. Replaces the Google Form Jeremy is using today.

### Tier B — should ship for cutover, can slip 1-2 weeks post-flip

10. **Sponsors CRUD** — list, create, edit, logo upload, year tagging. Not blocking cutover because we have 0 current sponsors.
11. **Board CRUD** — list, create, edit, photo upload, reorder. Can ship with seed data and edit via DB if needed for v1.
12. **Documents CRUD** — list, upload PDF, set metadata. Can ship with bylaws + IRS letter only.
13. **Volunteer opportunities CRUD** — list, create, edit.
14. **Committees CRUD** — list, create, edit. Seeded with 11 existing committees from old SE site; chairs assigned after launch.

### Tier C — defer to post-launch (Phase 1.5)

15. **About page rich-text blocks** — for cutover, hardcode the mission copy (real copy from SE site) and the "what dues fund" placeholder with board sign-off. Convert to admin-editable blocks within 30 days post-launch.
16. **Email aliases on contact page** — same: hardcode strings for v1, make editable later.

This staging means the *board-critical* edits (news, events, prices, hero CTA) ship Day 1, and the *yearly* edits (mission copy, aliases) ship within a month. None of the deferred work blocks the SE kill date.

---

## Admin roles

From CLAUDE.md: super_admin, content_admin, payments_admin, store_admin, readonly_admin. Phase 1 doesn't need all five.

**Phase 1 roles:**

- **super_admin** — Jeremy + 1 other (Carol or Ashley Olson). Can do anything including manage users.
- **content_admin** — Secretary + anyone the President designates. Can edit all content types but not users or financial settings.
- **readonly_admin** — Treasurer (Chevon) view-only for payments dashboard.

**Defer:** payments_admin and store_admin. We don't have a store, and payments oversight is fine under super_admin for v1.

**Per-content-type permissions in Phase 1:** Keep simple. content_admin can edit everything except billing/payments dashboard and user management. Don't build per-collection permission matrices yet.

---

## What admins should NOT be able to do

Drawing the line clearly so the next webmaster knows where their job starts:

- Change the nav structure (5 top-level items are fixed in Phase 1)
- Change page layouts or component structure
- Edit privacy policy (legal-adjacent, set once)
- Change Stripe API keys, Supabase keys, or any env vars
- Deploy code
- Modify the database schema

These are webmaster tasks. If a board member wants any of them, that's a conversation with the webmaster, which is the right friction.

(The RRISD school-affiliation disclaimer is intentionally NOT on this list — it's admin-editable via `site_settings.school_affiliation_disclaimer` with a known-good default seeded at install, in case RRISD updates required wording.)

---

## Editor UX requirements

For each admin form, the bar:

1. **Inline image upload** — drag-drop or click-to-upload. Show preview. Store in Supabase Storage. Return a CDN URL.
2. **Rich text editor for body fields** — bold, italic, links, headings (H2/H3 only), bullets, numbered lists, blockquote, inline image. No raw HTML. Plain enough that a Word user gets it instantly.
3. **Draft / Publish toggle** — for news and events. Drafts visible only to admins.
4. **Preview before publish** — opens the page in a new tab with `?preview=draft-id`.
5. **Confirm before destructive actions** — delete, unpublish.
6. **Audit log** — who edited what, when. Phase 1 minimum: last_edited_by + last_edited_at on every record. Full history is Phase 2.
7. **Validation messages in plain English** — "Price must be a number" not "Validation error: price.type expected integer."

---

## The handoff doc (Phase 3 deliverable — deferred)

Deferred to Phase 3 because the contents will drift as we build, and writing it now means rewriting it later. For Phase 1 cutover, Jeremy holds the institutional knowledge. Handbook gets written once the admin UI is stable and we know what's actually worth documenting.

When we do write it: a "Booster Club Webmaster Handbook" PDF that lives at `/documents/webmaster-handbook.pdf` (admin-only, public=false) and gets handed to the next webmaster when Jeremy rotates out.

**Contents (sketch — will be defined when actually written in Phase 3):** day-one access checklist, what board members can do without code, what requires a developer, step-by-step guides for common tasks, annual checklist, what to do if something breaks.

This doc is what makes "easy to hand down" real long-term. Without it, the principle is aspirational. But it's not blocking cutover.

---

## What stays as code (not editable in admin)

The exceptions, named explicitly so we're disciplined about it:

1. **Privacy policy** — `/privacy` content. Set once, low risk, legally reviewed.
2. **404 page text** — structural.
3. **Email templates for transactional emails** (receipt, password reset) — Phase 2 concern.
4. **Page layouts, components, routing, styling** — webmaster territory.
5. **Stripe webhook handler logic, Supabase RLS policies, auth flows** — webmaster territory.

That's it. Everything else editable. (Note: the RRISD school-affiliation disclaimer is admin-editable via `site_settings.school_affiliation_disclaimer` — seeded with a known-good default per spec_review G4, but editable in case RRISD updates required wording.)

---

## Data model summary (writing the DB schema later, this is the input)

Tables Phase 1 needs:

- `auth.users` (Supabase Auth built-in — not a table we create)
- `user_roles` (super_admin, content_admin, readonly_admin)
- `news_posts`
- `events`
- `sponsors`
- `sponsorship_tiers`
- `membership_tiers`
- `memberships` (records of who signed up at what tier — replaces the Google Form sheet)
- `board_members`
- `committees`
- `volunteer_opportunities`
- `documents`
- `site_settings` (singleton, key-value or JSON column)
- `payments` (recorded from Stripe webhooks, linked to memberships/donations/sponsorships)

14 tables (plus `auth.users` from Supabase). Audit history is handled inline via `last_edited_by` / `updated_at` columns, not a separate `audit_log` table in Phase 1. **`schema.md` is the source of truth for all column definitions.** This doc lists tables and high-level intent only; field-level changes go in schema.md, not here.

**Notable points for admins (full definitions in schema.md):**
- `memberships` table captures everything the Google Form does today (parent info, t-shirt sizes, employer match, SportsYou opt-in, public-listing opt-in)
- `payments.method` is where the payment type lives (Stripe, cash, check, $0, other) — NOT on `memberships`. Cash/check entries are admin-recorded `payments` rows linked back to the membership.
- A `BEFORE INSERT/UPDATE` trigger on `memberships` (`validate_membership_paid_state`) enforces that `paid = true` requires either a linked `payment_id` or a $0-priced tier. The trigger does a live subquery against `membership_tiers.price_cents`, so it stays correct even if tier prices change.
- `sponsors.payment_id` (nullable FK to `payments`) links inbound sponsorship dollars to the sponsor record for Treasurer reconciliation
- `memberships.active` is for soft-deleting duplicates, test data, or spam — NOT for year rollover. Year rollover is handled by filtering on `year`. Admin list default filter is current year, no `active` filter (soft-deleted rows visible like a trash can).

---

## Risks to the "easy handoff" promise

Being honest about where this could fail:

1. **Rich text editors are never as good as Word.** Even the best (TipTap, Lexical) have quirks. Mitigation: pick one mature library, train Jeremy first, document the gotchas in the handbook.
2. **Image uploads break in subtle ways** (giant files, wrong format, slow uploads). Mitigation: client-side resize + format check before upload, max 5MB, clear error messages.
3. **The next webmaster might quit.** Mitigation: the handbook is the recovery plan. Also: keep the stack boring (Next.js + Supabase + Stripe are mainstream — easy to hire help on).
4. **Board doesn't actually use admin features and reverts to "Jeremy can you update X"** — the failure mode of every nonprofit website. Mitigation: live training session at a board meeting where every officer logs in and edits one thing. Make it ceremonial.

---

## Open items for review with you

1. Confirm Tier A / Tier B / Tier C split. Any items you want moved up or down?
2. Confirm 3-role model (super, content, readonly) for Phase 1.
3. Confirm we're hardcoding About-page copy for cutover and converting to admin-editable in Phase 1.5.
