-- 116_community_partners_batch.sql
--
-- Seven more Community Partners, supplied by Jeremy 2026-08-08. All in-kind
-- (meals, food, gift cards) — none of them bought a sponsorship level.
--
-- ⚠️ Name + logo + link only, per migration 115. No taglines, no descriptions,
-- no dollar values. The club is a 501(c)(3): acknowledgment is fine, promotional
-- copy would be advertising. There is deliberately no column here to put one in.
--
-- ── ORDERING: sort_order 0 for every partner, on purpose ──
-- getCommunityPartners orders by sort_order THEN name, so leaving all partners
-- at 0 makes the list alphabetical automatically and means adding a partner
-- never requires picking a number or renumbering anything. It also avoids
-- implying a ranking among in-kind supporters, which is the whole point of not
-- having levels here. Rudy's is dropped from 1 to 0 to join the same scheme.
--
-- ── URL NOTES (each verified HTTP 200 on 2026-08-08 before writing) ──
-- ⚠️ Tony C's: the URL originally supplied was `tonycspizza.com`, which is WRONG
--    twice over — it serves a near-empty page titled "TC4 Beer Garden" with no
--    mention of Tony C's, and it has NO TLS (https returns nothing at all), so
--    linking it from an https site would have been a broken, insecure link.
--    Corrected to tonycs.com, confirmed as the real site and confirmed to list
--    the Avery Ranch location on W Parmer Ln that the logo names.
-- Chicoine had no URL supplied; chicoinechiropractic.com was located and then
--    confirmed by Jeremy. Title reads "North Austin Chiropractor in Wells
--    Branch", consistent with the McNeil feeder area.
-- Phil's and Tony C's both point at location-specific pages, as supplied.
--
-- Logos: prepped by MavericksWebsite/partner_logos/prep_logos.py from PINNED
-- sources in that folder. No white-keying was applied to any of them — four are
-- white text on a coloured field (Jack Allen's, The League, Phil's, Mighty Fine)
-- where keying would eat the lettering, and the rest sit on white, which is
-- invisible against this page anyway. Same call as Capstone's white-on-red mark.

begin;

-- Alphabetical-by-name ordering for all partners, including the existing row.
update sponsors set sort_order = 0
where kind = 'community_partner' and year = '2026-27';

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select v.name, v.logo_url, v.website_url, null, '2026-27', 'community_partner', true, 0, false
from (values
  ('Amy''s Ice Creams',           'amys-ice-creams.png',       'https://amysicecreams.com/'),
  ('Chicoine Chiropractic',       'chicoine-chiropractic.png', 'https://chicoinechiropractic.com/'),
  ('Jack Allen''s Kitchen',       'jack-allens.png',           'https://jackallenskitchen.com/'),
  ('Mighty Fine Burgers',         'mighty-fine.png',           'https://www.mightyfineburgers.com/'),
  ('Phil''s Icehouse',            'phils-icehouse.png',        'https://www.philsicehouse.com/phils-in-north-austinville/'),
  ('The League Kitchen & Tavern', 'the-league.png',            'https://www.leaguekitchen.com/'),
  ('Tony C''s Coal Fired Pizza',  'tony-cs.png',               'https://www.tonycs.com/locations#order-now-section')
) as v(name, logo_url, website_url)
where not exists (
  select 1 from sponsors s
  where s.name = v.name and s.year = '2026-27' and s.kind = 'community_partner'
);

commit;

-- Verification:
--   select name, logo_url, website_url from sponsors
--   where kind='community_partner' and year='2026-27' and active
--   order by sort_order, name;
--     -> 8 rows, alphabetical, Rudy's sixth
--
--   select kind, count(*) from sponsors where year='2026-27' and active group by kind;
--     -> sponsor 6, community_partner 8
--
-- /boosters/donate is ISR revalidate=300, so allow ~5 minutes.
