-- 127_atfcu_blue_sponsor.sql
--
-- Austin Telco Federal Credit Union joins at BLUE ($500). Jeremy 2026-08-14.
--
-- URL verified before writing: atfcu.org and www.atfcu.org both 200 and the
-- title reads "Austin Telco Federal Credit Union", so this is the right ATFCU
-- (there are several similarly-abbreviated Texas credit unions — A+ FCU and
-- RBFCU both appear in sponsor_online_asks_2026.md and are NOT this one).
--
-- Display name is the full "Austin Telco Federal Credit Union" rather than the
-- lowercase "atfcu" wordmark in the logo: the name is what screen readers
-- announce and what the aria-label says, and the initialism alone tells a
-- visitor nothing.
--
-- Logo: vendor-supplied primary mark, 1276x301 with real transparency and no
-- background panel — trimmed on its alpha bbox, no judgement needed about what
-- was padding vs artwork. Renders 200x45 in the Blue 200x96 box.
--
-- ── Blue is renumbered ALPHABETICALLY while we are here ──
-- It was 9/10/11 in historical add-order (Luv Braces, Mama Betty's, Freddie's).
-- Gold and Community Partners are both already alphabetical within their group,
-- so this brings Blue in line and means the next Blue sponsor slots in by name
-- instead of landing at the end. No ranking is implied within a tier.

begin;

do $$
declare n int;
begin
  select count(*) into n from sponsorship_tiers where year='2026-27' and name='Blue' and active;
  if n <> 1 then raise exception 'Expected 1 active Blue tier, found %', n; end if;
end $$;

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select 'Austin Telco Federal Credit Union', 'atfcu.png', 'https://www.atfcu.org/',
       (select id from sponsorship_tiers where year='2026-27' and name='Blue' and active),
       '2026-27', 'sponsor', true, 9, false
where not exists (
  select 1 from sponsors where name='Austin Telco Federal Credit Union' and year='2026-27'
);

-- Blue, alphabetical: ATFCU(9) · Freddie's(10) · Luv Braces(11) · Mama Betty's(12)
update sponsors set sort_order=10 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';
update sponsors set sort_order=11 where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=12 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';

commit;

-- Verification: 12 active sponsors — Platinum x2, Gold x6, Blue x4.
