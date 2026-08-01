-- 105_resources_boy_checklist.sql
--
-- Posts Coach's "2026-2027 Beginning of Year Checklist" to /resources under
-- Registration & Forms, and cleans up the SportsYou row.
--
-- The PDF was edited before upload (source: ~/Downloads, edited copy kept at
-- MavericksWebsite/boy_checklist/boy-checklist-2026-27.pdf):
--   1. "Code: EBQA-WNBB" REMOVED and replaced with "Email
--      contact@mcneilmavericks.org for the team code." The SportsYou join code
--      is a credential for the channel Coach uses to message families; posting
--      it on a public page hands that channel to anyone who finds the page and
--      cannot be un-published once indexed. Gated behind a human instead.
--   2. The "Sponsorship Letter" link was a raw Supabase storage URL
--      (project ref + bucket path baked into a parent-facing doc, breaks
--      silently if the file is ever re-uploaded) -> now /boosters/sponsor.
--   3. The Instagram link's share-sheet tracking params were stripped.
--   4. A mailto: annotation + underline was added on the new email address so
--      it matches the other links in the doc.
-- All 8 original link annotations were preserved (verified by rebuilding the
-- link set from the captured rects), plus the new mailto = 9 total.
--
-- sort_order 0 puts it above RRISD Athletic Forms (1): the checklist is the
-- "start here" doc that points at everything else, including Rank One.
--
-- No ?download= param, matching the ONE MAV deck (migration 097): a checklist
-- should open in a tab, and parents who want it can still print or save.
--
-- The label is year-stamped so it visibly ages. The description deliberately
-- carries no dates.

begin;

insert into resource_links (section, sort_order, label, url, description, icon_hint, active)
values (
  'registration_forms',
  0,
  '2026-27 Beginning of Year Checklist',
  'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/documents/checklists/boy-checklist-2026-27.pdf',
  'Everything to take care of before the season starts, from Coach Gardner. Every item links straight to the sign-up, form, or page you need.',
  'pdf',
  true
);

-- The live SportsYou description referenced "the SE capture" -- our internal
-- name for the SportsEngine scrape doc. It has been public since migration 064
-- and means nothing to a parent. Rewritten, and pointed at contact@ so it
-- matches the instruction now printed in the checklist PDF (both aliases are
-- Google Groups delivering to the booster Gmail, so this is wording, not
-- routing).
update resource_links
set description = 'Team messaging app for parents and players. Email contact@mcneilmavericks.org for the team code.'
where section = 'communications'
  and label = 'SportsYou (Team Messaging)';

commit;
