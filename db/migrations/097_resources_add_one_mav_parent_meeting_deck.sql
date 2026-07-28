-- 097_resources_add_one_mav_parent_meeting_deck.sql
--
-- Adds Coach Gardner's ONE MAV Parent & Athlete Meeting presentation (the
-- 7/27/2026 season-kickoff deck, 18 slides) to /resources (Forms & Links)
-- under the "Resources" section at sort_order 0, i.e. ABOVE "McNeil High
-- School" (1) and "HUDL" (2) — it's the most timely item on the page for the
-- next few weeks.
--
-- Jeremy 2026-07-28, at Coach Gardner's request ("could you post the
-- presentation from last night"). Coach will point parents at the Forms &
-- Links page from SportsYou, so NO homepage link/announcement by design.
--
-- PDF lives in the public `documents` bucket, following the existing
-- rosters/ + schedules/ + sponsorship/ convention:
--   documents/meetings/one-mav-parent-athlete-meeting-2026-07-27.pdf
-- No `?download=` param (unlike the sponsorship letter) — a presentation
-- should open in a tab, not download.
--
-- DELIBERATE: the label is date-stamped and the description says nothing
-- about practice/game dates or registration systems. The deck embeds an
-- August practice calendar (a photo of a printed sheet, two scrimmages still
-- TBD) and the 2026 varsity schedule marked "subject to change" — /schedule
-- remains the live source of truth. Do not relabel this row as a schedule
-- link, and do not let it become the schedule link parents bookmark.
--
-- NOTE (unresolved as of this migration): deck slide 9 instructs parents to
-- complete paperwork in **RankOne.com** and requires GREEN status before
-- Aug 3, but the `registration_forms` row "Aktivate (Athletic Registration)"
-- says Aktivate "replaces the old RankOne system." One of the two is stale.
-- Flagged to Jeremy to confirm with Coach Gardner; this migration takes no
-- position on it either way.

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
VALUES (
  'resources',
  'ONE MAV Parent & Athlete Meeting (July 27, 2026)',
  'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/documents/meetings/one-mav-parent-athlete-meeting-2026-07-27.pdf',
  'Coach Gardner''s presentation from the parent meeting: program standards, academics, safety protocols, and parent expectations.',
  'pdf',
  0,
  true
);

COMMIT;
