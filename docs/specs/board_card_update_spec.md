# Spec: Board Member Card Update (boosters page)
# File: docs/specs/board_card_update_spec.md
# Status: BUILT, pending review + batched deploy (2026-06-14)
# Date: 2026-06-14

## As-built (2026-06-14)
Built but NOT yet applied to prod / deployed — Jeremy is batching with other
edits, then we apply migration + push code in one go and verify.

Schema decisions (resolved against the live schema, not guessed):
- Email: `board_members.email_alias` (nullable text) already exists. Reused it;
  no new column. Holds the shared gmail placeholder until J9 .org aliases land.
- Soft-delete: `board_members.active` (boolean) already exists. Chevon
  deactivated (`active = false`), not hard-deleted.
- Vacancy: `name` is NOT NULL and no vacancy flag existed. Added explicit
  `is_vacant boolean NOT NULL DEFAULT false` (migration 061) rather than overload
  `name` with a sentinel string — the card render keys off the flag, not a magic
  string. Sylvia's row: `is_vacant = true`, `email_alias = NULL`, role unchanged
  ("VP of Merchandise", the existing text).

Other resolved decisions:
- Vacancy button label: **"Join a Committee"** (Jeremy chose over "Get Involved").
- Vacancy button style: navy (`bg-mavs-navy text-white`).

Files: `db/migrations/061_board_card_update.sql` (+ `061_rollback.sql`),
`lib/types.ts` (BoardMember gains `is_vacant`), `app/boosters/page.tsx`
(removed `initialsFor` + headshot/initials block; compact bordered cards;
vacancy branch). Migration dry-run validated in a rolled-back transaction:
8 active rows (7 filled w/ gmail + Sylvia vacancy), Chevon gone, Ashley = Treasurer.

## Summary
Update /boosters 2026-27 board display: remove headshot/initials blocks, add
contact email per member, apply roster changes (Chevon out, Ashley to Treasurer
solo, Sylvia's VP Merchandise converted to a vacancy card with a recruitment
button). Compact the cards.

## Roster changes (data)
- DELETE Chevon Williams (Treasurer). Soft-delete via `active = false`.
- UPDATE Ashley Olson: title "Co-Treasurer" -> "Treasurer".
- Sylvia Brito (VP Merchandise): convert to vacancy. Title stays "VP of
  Merchandise". `is_vacant = true`, no email.
- All remaining filled members: contact email = mcneilfootballboosters@gmail.com
  (same for everyone, placeholder until .org aliases land in J9).

## Card component changes
Filled member card (compact):
- REMOVE the gray initials/headshot block entirely.
- Render: name (bold), title (muted), email as a mailto link below title.
- Light card border, ~1/3 of prior height (no image block).

Vacancy card (Sylvia / VP Merchandise):
- Same compact footprint.
- Title: "VP of Merchandise"
- In place of name: "Position Open" (muted weight, not bold).
- No email.
- Navy button "Join a Committee" linking to /boosters/committees.

## Acceptance criteria
- /boosters shows: Carol (President), Ashley (Treasurer), [remaining filled
  members with gmail], plus VP Merchandise vacancy card with button to
  /boosters/committees.
- Chevon no longer appears.
- No card shows an initials/headshot block.
- Every filled card shows mcneilfootballboosters@gmail.com as a mailto link.
- Vacancy card shows "Position Open", no email, working button to committees.
- Cards visibly shorter than before.

## Out of scope (follow-up, pending board)
- Short bios per board member. Logged in followups.md (board members section).

## Notes
- Chevon has no admin access to revoke (confirmed). Display-only removal.
- current_board_year = "2026-27" governs this content. Do not touch current_year.
