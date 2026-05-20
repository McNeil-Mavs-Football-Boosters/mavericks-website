# Spec: Print View (PDF) for Rosters & Schedule, plus Coach Wallin update

Written 2026-05-19. Replaces the existing "Print" buttons on roster and schedule pages with "Print View" links that open the canonical PDFs the booster club hands out at meetings. Also a small content update on Coach Wallin's roster entry.

## Scope

Two unrelated changes shipped together because both are small:

1. PDF print views for varsity / JV / freshman green / freshman blue rosters and for the schedule.
2. Coach Wallin's name and position updated in the coaches data.

## Part 1 — PDF print views

### What this is

The existing rendered roster and schedule pages stay. We're adding a button labeled "Print View" that opens the official PDF (the one parents and coaches have been handed at meetings) in a new tab. The current "Print" button is removed.

### Why this is the right call

Parents and coaches want printouts that match what they've been handed in person. Re-rendering a roster from the database produces a different layout than the official PDF, even if the data matches. The standard at peer district sites is to link the actual PDF.

### Storage

New Supabase Storage bucket called `documents`. Configuration:

- **Public read.** Same policy pattern as `site-images`.
- **Per-file cap: 5MB.** Current PDFs are well under 1MB; 5MB gives headroom for future PDFs that include embedded photos without inviting waste.
- **MIME types:** `application/pdf` only.

Folder structure inside the bucket:

```
documents/
  rosters/
    varsity-2025.pdf
    jv-2025.pdf
    freshman-2025.pdf
  schedules/
    2025-26.pdf
```

### Files to upload

The four PDFs live in the repo at `docs/` and need to be uploaded to Storage:

| Source file (in repo `docs/`) | Storage path |
|---|---|
| `2025 McNeil Football Rosters - Varsity.pdf` | `documents/rosters/varsity-2025.pdf` |
| `2025 McNeil Football Rosters - JV.pdf` | `documents/rosters/jv-2025.pdf` |
| `2025 McNeil Football Rosters - Freshmen.pdf` | `documents/rosters/freshman-2025.pdf` |
| `2025 Football schedule.pdf` | `documents/schedules/2025-26.pdf` |

Jeremy uploads these manually via Studio after CC creates the bucket. The bylaws PDF and the membership PDF stay where they currently live (membership is already wired into the join page; bylaws are out of scope).

Note: per Jeremy's request, freshman Green and freshman Blue both point at the **same** freshman PDF for 2025-26. Two separate database rows / fields, both holding `documents/rosters/freshman-2025.pdf`. When the new freshman coaching staff splits them next season, only the Blue row's `pdf_storage_path` gets updated.

### Schema changes

**Add `pdf_storage_path` to the `rosters` table:**

```sql
alter table rosters add column pdf_storage_path text;
```

Nullable on purpose — a season may exist before its PDF is ready.

**For the schedule PDF, there are two options:**

**Option A — single shared field on `site_settings`.** Add `schedule_pdf_storage_path text` to `site_settings`. All four team-level schedule pages link to the same PDF. Simple but wrong long-term.

**Option B — per-team schedule PDFs from day one.** Add `schedule_pdf_storage_path text` to whatever table holds team-level schedule data (likely `team_levels` or similar — CC should verify). All four rows seeded with the same path for 2025-26, divergeable later.

**Pick B.** Jeremy was explicit: "don't assume it will always be the same." Building the per-team field now means no migration when the JV coach hands him a JV-specific PDF in August. Same pattern as the freshman roster two-rows-one-value setup.

CC needs to verify what table holds team-level schedule data before writing the ALTER. If there's no per-team schedule table, the question is whether each `team_levels` row already has its own data and just needs a PDF column added, or whether the schedule is currently a single global thing pulled from `games`. Flag this at apply-time.

### Migration

Single migration file, next sequential number (likely 038):

```sql
-- documents bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documents', 'documents', true, 5242880, array['application/pdf']);

-- public read policy for the documents bucket
create policy documents_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'documents');

-- pdf_storage_path on rosters
alter table rosters add column pdf_storage_path text;

-- pdf_storage_path on team_levels (or wherever team-level schedule lives — CC verifies)
alter table team_levels add column schedule_pdf_storage_path text;

-- seed the roster PDFs for 2025-26
-- (CC must verify column names: this assumes rosters are keyed by team_level + year)
update rosters set pdf_storage_path = 'documents/rosters/varsity-2025.pdf'
  where team_level = 'varsity' and year = '2025-26';

update rosters set pdf_storage_path = 'documents/rosters/jv-2025.pdf'
  where team_level = 'jv' and year = '2025-26';

update rosters set pdf_storage_path = 'documents/rosters/freshman-2025.pdf'
  where team_level in ('freshman_green', 'freshman_blue') and year = '2025-26';

-- seed the schedule PDF for all four levels
update team_levels set schedule_pdf_storage_path = 'documents/schedules/2025-26.pdf';
```

CC must verify table and column names against the actual schema before writing the UPDATE statements. The patterns above assume `rosters` has `team_level` and `year` columns. If not, adjust to match what's there.

### Verification

```sql
-- bucket exists
select id, public, file_size_limit, allowed_mime_types from storage.buckets where id = 'documents';
-- expect 1 row, public=true, limit=5242880, mime=['application/pdf']

-- roster PDF paths set
select team_level, year, pdf_storage_path from rosters where year = '2025-26' order by team_level;
-- expect 4 rows (varsity, jv, freshman_green, freshman_blue), all with non-null paths

-- schedule PDF paths set
select team_level, schedule_pdf_storage_path from team_levels order by team_level;
-- expect 4 rows, all with the same path
```

### Frontend changes

Each roster page (`/roster/varsity`, `/roster/jv`, `/roster/freshman/green`, `/roster/freshman/blue`) currently has a "Print" button. Each schedule page (likely `/schedule` or `/schedule/[level]`) has one too. CC should locate these and replace each with a "Print View" link.

The link:

```
<a href={publicStorageUrl(roster.pdf_storage_path)}
   target="_blank"
   rel="noopener noreferrer"
   class="[existing button class — match what Print used]">
  Print View
</a>
```

Use the existing `publicStorageUrl()` helper from `lib/storage.ts` (if it doesn't exist, look for an equivalent — there's one in use by the hero carousel work).

**Empty state:** if `pdf_storage_path` is null on the row, hide the button. Don't render "Print View" pointing at a broken URL.

**The old "Print" button is removed entirely.** Don't keep both. Jeremy's earlier guidance: two buttons doing similar things confuses people.

### Acceptance criteria for Part 1

1. New `documents` bucket exists with public read, 5MB cap, PDF-only MIME restriction.
2. Jeremy has uploaded the four PDFs to the paths in the table above. CC does not upload these — Jeremy does it via Studio after the bucket exists.
3. Each roster row for 2025-26 has its `pdf_storage_path` populated.
4. Each `team_levels` row has `schedule_pdf_storage_path` populated to the shared 2025-26 schedule.
5. "Print" buttons removed from all roster and schedule pages.
6. "Print View" links added in the same visual position, opening the PDF in a new tab.
7. If `pdf_storage_path` is null on a roster, no button appears.
8. Click "Print View" on `/roster/varsity` opens the varsity PDF. Same pattern works for JV, freshman green, freshman blue, and the schedule.
9. Freshman green and freshman blue both link to the same PDF for now.

## Part 2 — Coach Wallin update

### What this is

Two field edits on Coach Wallin's row in the coaches data:

- **Name:** confirm it reads "Douglas Wallin" (not "Doug" or "D. Wallin"). Update if currently abbreviated.
- **Position:** change to "Defensive Line Coach" from whatever it currently is.

He is **not** the head coach. The head coach slot remains empty per Jeremy's prior decision. If Wallin is currently sitting in the head coach slot as a placeholder, move him out — he should appear as a regular assistant alongside the others.

### Implementation

CC reads the current `coaches` row for Wallin first:

```sql
select id, name, position, sort_order from coaches where name ilike '%wallin%';
```

Then writes the UPDATE based on what's actually there:

```sql
update coaches
set name = 'Douglas Wallin',
    position = 'Defensive Line Coach'
where id = '<the uuid from the select>';
```

If Wallin's row has him as head coach (e.g. position field says "Head Coach" or there's a separate `is_head_coach` flag), also clear that. Flag it before applying so Jeremy can confirm.

### Verification

```sql
select name, position from coaches where name = 'Douglas Wallin';
-- expect: 'Douglas Wallin' | 'Defensive Line Coach'
```

### Acceptance criteria for Part 2

1. Coach Wallin's row shows name "Douglas Wallin" and position "Defensive Line Coach."
2. Head coach slot remains empty on the public coaches page.
3. The `/coaches` page (or wherever the staff list renders) shows Wallin in the assistants section with the updated title.

## Implementation order

Two commits in one CC session:

**Commit 1 — migration + frontend for Part 1.** Bucket, schema columns, seed updates, button swap on all roster + schedule pages. Push.

**Commit 2 — Wallin update.** Tiny migration or one-line data update + verification. Push.

After Commit 1 pushes, Jeremy uploads the four PDFs via Studio. Pages will show the "Print View" button as soon as the upload completes (the path is already in the DB; the storage object just needs to exist). If Jeremy delays uploading, the buttons appear but clicks return 404 until upload happens. Acceptable.

## Rollback

- **Migration:** rollback file drops the new columns from `rosters` and `team_levels`, drops the bucket policy, deletes the bucket. Storage files in `documents/` are wiped with the bucket.
- **Frontend:** revert the commit; "Print" buttons return.
- **Wallin:** the previous coach values are recoverable from git history of the seed migration that originally inserted them.

## Open follow-ups created by this work

Add to `followups.md` after this commit:

- **Admin UI for PDF uploads.** Right now Jeremy uploads via Studio and CC runs UPDATE statements. Phase 2: roster edit form has a "Replace PDF" button that uploads + updates the path in one action. Same for schedule. Same for any other PDF the site adds.
- **Freshman Green/Blue PDF split.** When the new freshman coaches hand Jeremy team-specific PDFs, upload them as `documents/rosters/freshman-green-2026.pdf` and `documents/rosters/freshman-blue-2026.pdf` and UPDATE only the Blue row (or both if Green changes too).
- **PDF preview on the page itself.** Some district sites embed the PDF inline below the rendered roster instead of (or in addition to) linking it. Not in scope here; revisit if parents want it.

## Shipped state (2026-05-19)

Both parts landed in one CC session, plus two follow-up commits.

**Conflicts surfaced + resolved at apply-time** (per "default to your reading" guidance):

- **`team_levels` table does not exist** in this codebase. `team_level` is an ENUM (`varsity, jv, freshman`). The per-team-per-year anchor that already exists at the cardinality the spec wants is `rosters` (one row per `year + team_level + team_designation`). Added BOTH `pdf_storage_path` AND `schedule_pdf_storage_path` to `rosters`. Schedule-game pages now fetch the matching rosters row in parallel via `Promise.all` to resolve the PDF path.
- **Freshman color split is NOT in the team_level enum.** It lives in `rosters.team_designation` (text: `'Green'` / `'Blue'`). The spec's `team_level in ('freshman_green', 'freshman_blue')` would never match. Seed filters on `team_level = 'freshman'` alone, which catches both designation rows.
- **`documents` bucket already existed.** Created in or before migration 009 (`009_storage_policies.sql` already pre-baked the read + content_admin write policies for it). Bucket needed `UPDATE` for the size + MIME constraints, not `INSERT`.
- **Spec column name `position` was actually `role`** in `coaches`. Wallin update writes to `role`.
- **Helper `publicStorageUrl()` hardcodes `site-images`** (designed for hero). Added a sibling `publicObjectUrl()` in `lib/storage.ts` for bucket-PREFIXED paths like `documents/rosters/varsity-2025.pdf`. Two helpers coexist — both inline-documented.

**Implementation status by commit:**

- **Commit 1 (Part 1)** — Migration **038_print_view_pdfs.sql** + frontend swap on 5 affected pages. `documents` bucket configured (5 MB cap, `application/pdf` only). Two new columns on `rosters`. 4 roster PDF paths + 4 schedule PDF paths seeded for 2025-26. `components/shared/PrintViewLink.tsx` (server component, hides when null, sr-only "(opens PDF in new tab)" hint). `components/schedule/print-button.tsx` + `print-footer.tsx` **deleted entirely** (no remaining consumers; the two pre-existing `react-hooks/set-state-in-effect` errors in print-footer.tsx are gone with it). Practice schedule pages: Print button removed with no replacement (no PDF in this scope; browser Cmd-P still works natively). `Roster` interface in `lib/types.ts` extended with both new fields, both nullable. Commit `c919aa3`.
- **Commit 2 (Part 2)** — Migration **039_update_coach_wallin.sql**. SELECT before UPDATE confirmed Wallin was NOT in the head coach slot (`role_category = 'position_coach'`, not `head`) — no slot clearing needed. UPDATE flipped name `Coach Wallin → Douglas Wallin` and `role` `Position Coach → Defensive Line Coach`; `role_category` unchanged. Commit `cd27abb`.
- **PDF upload follow-ups** — Migration **040_fix_freshmen_pdf_path.sql** flips both freshman rows from `documents/rosters/freshman-2025.pdf` (singular) to `documents/rosters/freshmen-2025.pdf` (plural). Jeremy's preference: file stays plural in Storage; the underlying `team_level` enum stays singular. All four storage URLs verified `200 OK` via curl after upload + rename. Commit `4705b8b`.
- **Freshman → Freshmen UI rename** — Per Jeremy ("collective...of men"): every user-visible "Freshman" label switched to "Freshmen". Touches `components/layout/teamLinks.ts` (header + mobile dropdown items), both `[designation]` page teamLabel computations, and the practice schedule's `LEVEL_TITLES.freshman` + "Freshman Green & Blue" combined label. DB enum (`team_level = 'freshman'`), URL slugs (`/roster/freshman/green`), variable names (`freshman_has_blue`, `freshmanHasBlue`), and internal function names (`FreshmanRosterPage`) deliberately untouched. Commit `a27a08c`.

Final state of the four Print View URLs in production:

| Page | Storage URL |
|---|---|
| `/roster/varsity` Print View | `…/storage/v1/object/public/documents/rosters/varsity-2025.pdf` |
| `/roster/jv` Print View | `…/storage/v1/object/public/documents/rosters/jv-2025.pdf` |
| `/roster/freshman/{green,blue}` Print View | `…/storage/v1/object/public/documents/rosters/freshmen-2025.pdf` |
| `/schedule/games/*` Print View (all 4) | `…/storage/v1/object/public/documents/schedules/2025-26.pdf` |

All four 200 OK. Part 1 acceptance criteria 1–9 met; Part 2 criteria 1–3 met.
