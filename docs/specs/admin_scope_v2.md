# Admin Scope — Phase 1 (Football Pivot)

Written 2026-05-16. **Supersedes the original `admin_scope.md`** which was built around the booster-focused IA.

**Reads with:**
- `schema_v2.md` + `schema_v2_addendum.md` + `schema_content_v2_addendum2.md` + `schema_content_v2_addendum3.md` — data model
- `content_map_v2.md` + same addenda — routes and page structures
- `build_plan.md` — implementation step ordering

This doc covers: who can do what in admin, every admin page that needs to exist, editor UX requirements, sensitive operations, and the common workflows admins will actually run.

---

## Three admin roles

Phase 1 keeps the role model simple. Three values in the `user_role` enum:

```
super_admin   — full access including user management and irreversible operations
content_admin — full CRUD on all content; cannot manage other admins or override payments
readonly_admin — read-only across all content + payments. For treasurer.
```

**Why three and not five:** the original spec proposed `payments_admin` and `store_admin` separately. For Phase 1, the store doesn't exist (Phase 3+), and payments are tightly coupled to memberships — splitting would force two officers to coordinate routinely. Better to give Carol (President) and Kendra (VP Fundraising) full content_admin; Chevon (Treasurer) gets readonly so she can audit without accidents. Jeremy is super_admin.

**Role assignments at launch:**

| Person | Role | Reason |
|---|---|---|
| Jeremy Vest | super_admin | Site builder + Secretary |
| Carol Glinski | content_admin | President, primary content editor |
| Ashley Olson (or Root) | content_admin | Co-Treasurer, second-officer rule |
| Kendra Jalbert | content_admin | VP Fundraising, sponsor lead |
| Sylvia Brito | content_admin | VP Merch, will own store in Phase 3 |
| Chevon Williams | readonly_admin | Treasurer; reconciles payments |
| Head Coach (TBD) | content_admin | Owns schedule, roster, coaches pages |

**Two-officer rule:** every content type has at least two content_admins who could edit it. No bus factor of one. This is a practical rule, not enforced by schema.

---

## Permission matrix

What each role can do per content type. Read-only means "see in admin"; anon visitors see the public-visible subset regardless.

| Content type | super_admin | content_admin | readonly_admin |
|---|---|---|---|
| user_roles | CRUD | — | — |
| site_settings | Update | Update | Read |
| news_posts | CRUD | CRUD | Read |
| events (booster) | CRUD | CRUD | Read |
| games | CRUD | CRUD | Read |
| rosters | CRUD | CRUD | Read |
| players | CRUD | CRUD | Read |
| coaches | CRUD | CRUD | Read |
| resource_links | CRUD | CRUD | Read |
| practice_schedules | CRUD | CRUD | Read |
| sponsors | CRUD | CRUD | Read |
| sponsorship_tiers | CRUD | CRUD | Read |
| sponsorship_inquiries | CRUD | CRUD | Read |
| board_members | CRUD | CRUD | Read |
| committees | CRUD | CRUD | Read |
| volunteer_opportunities | CRUD | CRUD | Read |
| documents | CRUD | CRUD | Read |
| membership_tiers | CRUD | CRUD | Read |
| memberships | CRUD | CRUD | Read |
| payments | CRUD (with friction) | Read + add manual | Read |

**Notes on payments:**
- `payments` rows can never be hard-deleted via the admin UI. Even super_admin uses status changes (`refunded`, `cancelled`) for corrections. The RLS policy already enforces this (no DELETE policy on payments). True deletes require database-level access. This is the financial-integrity safeguard from `schema.md`.
- content_admin can **add** manual payment rows (for cash/check entries received outside Stripe) but cannot edit Stripe-originated rows. Application-layer enforcement: the form is locked when `method = 'stripe'`. Schema doesn't enforce this; UI does.
- Refunds: super_admin only. UI is "Mark refunded" button, which sets `status = 'refunded'` and adds a notes line. No actual Stripe refund is triggered from our UI — that's done in the Stripe dashboard. We just reflect the state.

**Notes on site_settings:**
- content_admin can edit display-level fields (hero, copy, current_year, etc.).
- `freshman_has_blue` is editable by content_admin but flagged in the UI as "this changes public navigation." Two-step confirmation when toggling.
- Email aliases (`alias_president`, etc.) — editable by content_admin but Jeremy should keep an eye on these since they tie to Cloudflare Email Routing.

---

## Admin pages list

Every admin page that needs to exist for Phase 1. Each page follows the same pattern: list view with filter/sort, create/edit form, soft-archive button, audit info.

### Tier A — must exist before cutover

These are the pages required to operate the site after going live. Build order in `build_plan.md` Step 7 / 7b / 8.

| Route | Purpose | Special notes |
|---|---|---|
| `/admin` | Dashboard | Recent activity, quick links |
| `/admin/settings` | site_settings singleton | Includes the `freshman_has_blue` toggle and `current_year` |
| `/admin/news` | news_posts CRUD | Draft/publish toggle, TipTap editor, image upload |
| `/admin/events` | booster events CRUD | Draft/publish/cancelled toggle |
| `/admin/games` | games schedule CRUD | Score entry, status auto-flip, designation picker for freshman |
| `/admin/rosters` | rosters + players nested | Per-team CRUD; players managed inline |
| `/admin/coaches` | coaches CRUD | Role category dropdown, photo upload |
| `/admin/practice-schedules` | practice_schedules CRUD | Markdown body per team |
| `/admin/resource-links` | resource_links CRUD | Section dropdown, icon hint |
| `/admin/membership-tiers` | tier configuration | Perks array editor, drag-reorder |
| `/admin/sponsorship-tiers` | tier configuration | Same pattern as membership tiers |
| `/admin/memberships` | individual membership records | Filter by year + tier + paid status, CSV export, manual-paid override |
| `/admin/sponsorship-inquiries` | leads pipeline | Status workflow, notes, convert-to-sponsor action |
| `/admin/sponsors` | active sponsors CRUD | Logo upload, tier assignment |
| `/admin/board` | board_members CRUD | Year filter for historical |
| `/admin/committees` | committees CRUD | Cadence dropdown, chair selector |
| `/admin/volunteer-opportunities` | volunteer CRUD | Active toggle, sign-up URL |
| `/admin/documents` | documents CRUD | PDF upload, type tagging |
| `/admin/payments` | payments view + manual entries | Filter, export, restricted edits |

### Tier B — post-cutover, Phase 1 still

Not required for launch but should land within a few weeks. Build order in `build_plan.md` Step 14+.

| Route | Purpose |
|---|---|
| `/admin/users` | user_roles management (super_admin only) |
| `/admin/audit` | Recent activity feed across content types |
| `/admin/bulk-import` | CSV imports for memberships, players (one-time use Phase 1) |

### Tier C — Phase 2+

| Route | Purpose |
|---|---|
| `/admin/store/*` | Merch and orders |
| `/admin/photos` | Photo galleries |
| `/admin/newsletter` | Newsletter subscribers + campaigns |
| `/admin/stats` | Per-player stats (per "stats Phase 2" pickup) |

Total Phase 1 admin pages: 19 in Tier A, 3 in Tier B. All follow the same CRUD pattern, which means cost is roughly 19 × (small per-page work) + 1 × (shared CRUD scaffolding).

---

## Per-page detail — what's on each admin page

For the new pages introduced by the football pivot. Existing pages (news, events, settings, tiers, memberships, payments) follow patterns already in the original `admin_scope.md` and don't need re-spec.

### `/admin/games`

**List view:**
- Default filter: `year = current_year`, all team levels
- Filters: year (dropdown), team_level (dropdown: All/Varsity/JV/Freshman), team_designation (dropdown, only visible if any games have non-null designation), status (dropdown)
- Sort: game_date ASC by default
- Columns: Date, Team Level (+ designation badge if present), Opponent, Home/Away, Score (if final) or Status, Watch link (icon if present), Actions
- Bulk action: none in Phase 1. Phase 2 could add "mark multiple as cancelled" if weather hits.

**Create/Edit form:**
- Year (dropdown, defaults to current_year)
- Team Level (radio: Varsity / JV / Freshman)
- Team Designation (conditional: shows when Team Level = Freshman; options are "Green" + "Blue" if `freshman_has_blue = true` else just "Green"; defaults to "Green")
- Opponent (text, required)
- Opponent URL (text, optional)
- Game Date + Time (datetime picker)
- Location (text)
- Location URL (text, optional, validates as URL)
- Home / Away / Neutral (radio)
- Status (dropdown: scheduled / final / cancelled / postponed / tbd)
- Score: our_score, their_score (numeric inputs; only enabled when status != 'scheduled')
- Watch URL (text, optional)
- MaxPreps Game URL (text, optional)
- Notes (text, displayed below matchup on public page; e.g., "Homecoming")
- Featured (checkbox)

**Auto-behavior:** when admin saves a row with both scores filled and `status = 'scheduled'`, server flips status to `'final'` before write. Admin can override.

**Delete:** confirm dialog, "This will permanently remove the game record from the schedule. Are you sure?" → hard delete (games aren't soft-archived; if a game was scheduled and then cancelled, set status to 'cancelled' instead).

### `/admin/rosters`

**List view:**
- Default filter: `year = current_year`
- Rows: one per (year, team_level, team_designation). When `freshman_has_blue = false`, three rows (V / JV / Freshman Green). When true, four rows.
- Columns: Year, Team, Player Count (computed), Last Updated, Source Note, Actions
- "Edit" goes to roster detail page

**Roster detail page** (`/admin/rosters/[id]`):
- Header: year, team level + designation, source_note field, last_edited_by, updated_at
- Body markdown editor (TipTap) — for preamble copy
- **Players section** — nested CRUD:
  - Player table with inline edit
  - Columns: Sort, Jersey #, First Name, Last Name, Position, Grade, Height, Weight, Active toggle, Delete
  - "Add Player" button at the top
  - "Bulk Add" button: opens textarea, admin pastes rows like `12, Smith, John, QB, Sr., 6'2", 185`, server parses and inserts
  - Reorder via drag handle on each row
- Save All button: persists the body and all player edits in one transaction

**Empty state:** the seed creates empty rosters with `source_note = "Awaiting roster from coaching staff"`. The detail page shows that source_note + "No players yet" + "Add Player" CTA.

### `/admin/coaches`

**List view:**
- Default filter: `year = current_year, active = true`
- Filters: year, role_category, active (show archived toggle)
- Sort: role_category (head → coordinator → position_coach → trainer → staff), then sort_order
- Columns: Name, Role, Category, Phone, Email, Photo (thumbnail), Year, Active, Actions

**Create/Edit form:**
- Year (defaults to current_year)
- Name (required)
- Role (text, e.g., "Defensive Coordinator")
- Role Category (dropdown: Head / Coordinator / Position Coach / Trainer / Staff)
- Phone (text)
- Email (text)
- Photo upload (to `coach-photos` bucket)
- Bio (markdown, TipTap editor)
- Sort Order (numeric)
- Active (checkbox, default true)

**Validation warning** (not blocking): if admin sets Role Category = "Head" and there's already an active head coach for the year, warn "There is already a Head Coach for 2026-27 (current row name). Continue?"

**Why warn, not block:** during transitions (interim → permanent) you may briefly want two head coach rows. The warning catches accidents.

### `/admin/practice-schedules`

**List view:**
- Three rows: Varsity, JV, Freshman (per year)
- Columns: Team Level, Last Updated, Source Note, Active, Actions

**Edit form:**
- Year (dropdown)
- Team Level (read-only after creation — there's only ever one row per team_level per year)
- Body (TipTap markdown editor)
- Source Note (text)
- Active (checkbox)

**Empty state:** seed creates three empty rows. Admin sees them in the list with "Edit" buttons.

### `/admin/resource-links`

**List view:**
- Grouped by `section`: Registration & Forms, Communications, Resources, Stadiums, Other
- Within section: sort_order ASC
- Columns: Section, Label, URL, Icon Hint, Active, Actions
- Drag-reorder within section

**Create/Edit form:**
- Section (dropdown: 5 enum values)
- Label (text, required)
- URL (text, required, validates)
- Description (text, optional)
- Icon Hint (dropdown: external / pdf / form / video / other)
- Sort Order (auto-assigned, editable)
- Active (checkbox)

### `/admin/sponsorship-inquiries`

**List view:**
- Default filter: `year = current_year, status = 'new'`
- Filters: year, status, tier
- Sort: created_at DESC by default
- Columns: Business, Contact Name, Email, Tier (if selected), Status, Created, Last Edited

**Detail page** (`/admin/sponsorship-inquiries/[id]`):
- Inquiry fields (read-only after creation): business_name, contact_name, contact_email, contact_phone, message, logo (display if present)
- Editable: status (dropdown), tier_id (admin can correct), notes
- **Actions:**
  - "Mark in progress" button → status = 'in_progress'
  - "Mark closed-won" button → opens a form to create a corresponding `sponsors` row + optionally a `payments` row (manual entry). After save, inquiry status flips to 'closed_won' and the inquiry is linked to the sponsor in a notes line.
  - "Mark closed-lost" button → status = 'closed_lost'
  - "Send follow-up email" button → opens a pre-filled mailto: with Kendra's signature template

**Email notification on new inquiry:** when an anon submission lands, server sends an email via Resend to `sponsorship@mcneilmavericks.org` (or `boosters@` until aliases live). Subject: "New sponsorship inquiry from [business_name]". Body includes link to admin detail page.

---

## Editor UX requirements

Cross-cutting rules every admin form must follow:

1. **Save state visible.** Inline "Saving..." → "Saved" toast on every save. Never silent.
2. **Draft vs Published.** For news_posts and events, an explicit `status` field, not a hidden behavior. Drafts are visible in admin, not on public site.
3. **Preview before publish.** "Preview" button opens the public rendering in a new tab. Required for news_posts; nice-to-have for other content types.
4. **Image uploads resize client-side.** Max 2000px on long edge. Validated client-side before upload to avoid huge files.
5. **Plain-language validation.** Form errors say "Please enter a date in MM/DD/YYYY format," not "Invalid Date: NaN."
6. **Confirm before destructive actions.** Delete and Archive both confirm. Toggles like `active = false` don't need confirm; they're reversible. Real deletes do.
7. **Audit visible.** Every detail page shows "Last edited by [name] on [date]" prominently.
8. **Soft-archive over hard delete.** Default action for collections (sponsors, board, committees, etc.) is "Archive" (sets `active = false`), not delete. Hard delete is in an "Advanced" menu.
9. **Memberships in trash-can mode.** Per `schema.md` decision, default list filter for memberships is `year = current_year` with no `active` filter — admins see soft-deleted rows greyed out so they can un-delete.
10. **Year context everywhere.** Every list with year data shows the current_year filter prominently. Admin can switch year to view historical.
11. **Mobile-usable, not mobile-first.** Admin work is desktop work. Don't waste cycles making admin pages pretty on a 375px viewport, but don't break them either. Tested at 1280px+ primarily.

---

## Sensitive operations

Operations that get extra friction or are restricted to super_admin.

### Role assignment

- **Add a new admin:** super_admin only. `/admin/users/new`. Form requires email, role selection. After submit, server creates a Supabase Auth invite. New admin clicks invite link, sets password, lands on `/admin`.
- **Change role:** super_admin only. Two-step confirm. Audit log entry.
- **Remove an admin:** super_admin only. Soft-disable via `auth.users.banned = true` (Supabase Auth), don't delete the auth row. The user_roles row stays for historical audit.

### Toggling `freshman_has_blue`

- Available to content_admin via `/admin/settings`.
- UI warning: "Toggling this changes the public website navigation. Visitors will see Blue tabs appear/disappear immediately. Continue?"
- After toggle to true: prompt "Create a Freshman Blue roster now?" with shortcut to `/admin/rosters/new?level=freshman&designation=Blue`.

### Changing `current_year`

- Available to content_admin via `/admin/settings`.
- UI warning: "This changes which year's data displays publicly. Make sure new-year content (tiers, schedules, rosters) exists before switching."
- Auto-creates empty stubs on year advance: new rows in `rosters` (3), `practice_schedules` (3) for the new year. Admin still has to create new `membership_tiers`, `sponsorship_tiers`, `board_members` for the new year (no auto-copy from prior year).

### Payment record changes

- Edit a payment: super_admin only. Status, notes, payer info — yes. Amount — no, that requires database access. The amount on a Stripe-originated row is immutable.
- Refund: super_admin "Mark refunded" button. Sets status = 'refunded'. Does NOT trigger an actual Stripe refund (Stripe dashboard handles that). Notes field gets a stamped entry: "Marked refunded by [admin] on [date]."
- Delete a payment: not via admin UI. Service-role-key direct SQL only.

### Bulk operations

- Memberships CSV import: super_admin only. One-time use for migrating the 35 existing Google Form signups (per `build_plan.md` Step 12). Hidden from admin UI after the first run.
- Player bulk-add: any content_admin via the roster detail page. Friction is built in (textarea, parsed line by line, preview before commit).

---

## Common workflows

How admins actually use the system. These are the user stories the admin UI must support smoothly.

### Friday game results

1. Admin (Jeremy or coach-side admin) opens `/admin/games`
2. Filters to current year, Varsity, sees Friday's game in scheduled status
3. Clicks Edit
4. Enters our_score and their_score
5. Saves → server auto-flips status to 'final'
6. Public `/schedule/games/varsity` reflects within 60s (per revalidate setting)

Acceptable time: 2 minutes per game.

### Posting a news article

1. Carol opens `/admin/news`, clicks "New Post"
2. Types title, slug auto-generates (editable)
3. Writes body in TipTap, uploads a featured image
4. Status = Draft initially. Clicks Preview to see public render.
5. Sets status = Published, clicks Save
6. Article appears on `/news` and home page Latest News section within 60s

Acceptable time: 10-15 minutes for a typical post.

### Onboarding a new head coach (or any new admin)

1. Jeremy (super_admin) opens `/admin/users/new`
2. Enters email and role (content_admin)
3. New admin receives invite email, follows link, sets password
4. Jeremy can also add their coach record via `/admin/coaches` with role_category = head
5. Confirmation that public `/coaches` page now displays head coach

### Sponsorship inquiry flow

1. Prospect fills out `/boosters/sponsor` form
2. Kendra receives email notification
3. Kendra opens `/admin/sponsorship-inquiries`, sees new lead at top
4. Status = 'new'. Kendra clicks "Mark in progress"
5. Kendra emails or calls prospect, negotiates terms
6. When sponsor commits and pays (check or invoice): Kendra clicks "Mark closed-won" → form opens to create a `sponsors` row (pre-filled with business name, logo if uploaded) and optionally a `payments` row
7. After save, inquiry status = 'closed_won', sponsor appears on `/sponsors` and homepage strip immediately

### Seasonal roster intake

1. Head coach sends roster as PDF or Word doc to admin (Jeremy or another content_admin)
2. Admin opens `/admin/rosters`, finds the row for current_year + team_level + Green
3. Pastes a preamble (optional) — captains, returning players summary
4. Bulk Add players: pastes lines like `12, Smith, John, QB, Sr., 6'2", 185`, server parses
5. Reviews, edits any errors inline
6. Saves
7. Public `/roster/varsity` (or wherever) renders

Acceptable time: 30 minutes for a full Varsity roster of ~55 players, including double-checks.

### Activating Freshman Blue mid-summer

1. Coach decides to split freshman into Green and Blue squads
2. Admin opens `/admin/settings`
3. Toggles `freshman_has_blue` to true, confirms warning
4. System prompts: "Create a Freshman Blue roster now?" → admin says yes
5. New roster created with designation = 'Blue', body and players empty
6. Admin populates Blue roster from coach packet (same flow as Seasonal roster intake)
7. Admin tags appropriate games as Blue when scheduling
8. Public site shows Green / Blue tabs immediately

### Year rollover (end of season, prep for next)

1. Once the season is fully over (December-ish):
2. Admin creates next year's `membership_tiers` rows (copying current year's structure, updating prices/perks per board decisions)
3. Admin creates next year's `sponsorship_tiers` rows
4. Admin updates `board_members` rows: archives current year's, creates next year's for new officers
5. Admin updates `/admin/settings` → changes `current_year`
6. System auto-creates empty stubs for rosters, practice_schedules in the new year
7. Public site flips to displaying new year's data; old year's data remains in admin for reference

This is a once-per-year ceremony. Should take an hour of admin time, mostly spent thinking about tier perks.

---

## Empty admin states

Admin sees a different empty state from public visitors. The point: make it obvious what to do next.

| Content type | Admin empty state |
|---|---|
| news_posts | "No posts yet. [Create your first post →]" |
| events | "No events scheduled. [Create event →]" |
| games | "No games for 2026-27 yet. [Create game →]" plus a link to copy from previous year (Phase 2) |
| rosters | (Seeded with stubs; never empty) |
| coaches | "No coaches yet for 2026-27. [Add coach →]" with note about role_category recommendations |
| sponsors | "No sponsors yet. [Add sponsor →]" plus a link to sponsorship_inquiries |
| sponsorship_inquiries | "No active inquiries. [View public sponsorship page →]" |
| board_members | "No board members for 2026-27 yet. [Add member →]" |
| documents | "No documents uploaded. [Upload document →]" |
| memberships | "No memberships for 2026-27 yet. [View public join page →]" |

---

## What's not in scope

Calling out explicitly so it's not surprising:

- **No per-content-type permissions** (e.g., "can edit news but not events"). Phase 1 has one content_admin role with full content access. If we need finer grain later, easy to extend the role enum.
- **No approval workflows** (e.g., editor proposes, super_admin approves). Phase 1 trusts content_admins to publish directly.
- **No revision history beyond `last_edited_by` and `updated_at`.** Full diff history is Phase 2+. If admins want to revert, they paste from their own backup or memory.
- **No content scheduling** (e.g., "publish this post on Friday at 5pm"). Phase 1 is manual publish. If needed, Phase 2 adds a `publish_at` column on news_posts.
- **No collaborative editing.** Last write wins. Two admins editing the same row simultaneously will overwrite each other. Acceptable for a small org.
- **No public profiles for admins.** Admin names appear only in audit fields, not on public site.

---

## Open questions for Jeremy

None blocking; these are flagged for future thinking:

1. **Should there be a "request access" link on /admin/login?** I'd say no — admin invites are by email only, per super_admin discretion. Confirm.
2. **Audit log retention.** How long do we keep `last_edited_by` / `updated_at` history? My pick: forever, it's cheap and useful.
3. **Two-factor auth for admins.** Supabase Auth supports TOTP. Worth turning on for super_admin at least. My pick: yes for super_admin, optional for content_admin.

---

## What's next

`admin_scope_v2.md` locked unless Jeremy pushes back.

Next: patches to `build_plan.md`:
- Insert Step 4b (nav + home reshape + /boosters landing using current Step 4 content)
- Expand Step 5 (public routes for all the new content types)
- Renumber subsequent steps and revisit hard dates

Then consider whether to do the consolidated rewrite pass (one canonical schema.md, one canonical content_map.md, one canonical admin_scope.md replacing the addenda trail).
