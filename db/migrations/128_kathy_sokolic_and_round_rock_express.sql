-- 128_kathy_sokolic_and_round_rock_express.sql
--
-- Two additions, Jeremy 2026-08-14:
--   Kathy Sokolic, REALTOR®  -> BLUE sponsor ($500)
--   Round Rock Express       -> Community Partner
--
-- Both URLs verified 200 before writing: kathysokolicrealtor.com (title
-- "Realtor in Austin, TX"; www redirects to the apex, so the apex is stored) and
-- mlb.com/milb/round-rock (title "Official Round Rock Express Website").
--
-- ── ⚠️ KATHY'S LOGO: the first file supplied was the WHITE version ──
-- Kathy_Logo_White_LG.svg is 24 white fills to 5 blue. Both surfaces it would
-- appear on have WHITE backgrounds, so most of the mark would have been
-- invisible — the wordmark would have vanished and left a floating stripe.
-- Caught by counting fills before rendering; Jeremy supplied the black version.
-- Rasterised from Kathy_Logo_Black_LG.svg (24x #000000, 5x #2a74b8).
-- The bucket only accepts png/jpeg/webp, so SVGs are rasterised through headless
-- Chrome — same route Mama Betty's took.
--
-- ── ⚠️ ROUND ROCK: the supplied JPEG had a FAKE transparent background ──
-- "Dell Diamond Round Rock Express Logo.jpg" has the Photoshop transparency
-- CHECKERBOARD baked in as real pixels (corners alternate 255,255,255 and
-- 220,220,220). Published as-is it would render a grey checked rectangle. JPEG
-- cannot carry alpha at all, so there was nothing to recover.
-- Used the official mark from mlbstatic.com/team-logos/102.svg instead — real
-- vector, genuine transparency, and current. Same call as Santiago's, where the
-- screenshot had a black backing and their own site had the real file.
-- ⚠️ This is the "E" shield, MLB's canonical team logo, NOT the older
-- ROUND ROCK EXPRESS wordmark-with-train in Jeremy's image. If the wordmark is
-- wanted, it needs a clean source — the JPEG cannot provide one.
--
-- Also rejected: images.ctfassets.net/.../round-rock-affiliate-logo.svg, which
-- is the TEXAS RANGERS parent-club affiliate mark and is mostly white.
--
-- Blue stays alphabetical (127's scheme), so Kathy slots in at 11 and the two
-- below her shift. Partners carry sort_order 0 and are ordered by NAME at query
-- time, so Round Rock Express needs no renumbering.

begin;

do $$
declare n int;
begin
  select count(*) into n from sponsorship_tiers where year='2026-27' and name='Blue' and active;
  if n <> 1 then raise exception 'Expected 1 active Blue tier, found %', n; end if;
end $$;

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select 'Kathy Sokolic, REALTOR®', 'kathy-sokolic.png', 'https://kathysokolicrealtor.com/',
       (select id from sponsorship_tiers where year='2026-27' and name='Blue' and active),
       '2026-27', 'sponsor', true, 11, false
where not exists (
  select 1 from sponsors where name='Kathy Sokolic, REALTOR®' and year='2026-27'
);

-- Blue alphabetical: ATFCU(9) · Freddie's(10) · Kathy(11) · Luv Braces(12) · Mama Betty's(13)
update sponsors set sort_order=12 where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=13 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select 'Round Rock Express', 'round-rock-express.png', 'https://www.mlb.com/milb/round-rock',
       null, '2026-27', 'community_partner', true, 0, false
where not exists (
  select 1 from sponsors where name='Round Rock Express' and year='2026-27'
);

commit;

-- Verification: 13 active sponsors (Platinum 2 · Gold 6 · Blue 5), 6 partners.
