-- 112_sponsor_freddies_carwash.sql
--
-- Adds Freddie's Carwash as a Blue-tier ($500) sponsor for 2026-27. Jeremy
-- closed them 2026-08-04. Seventh sponsor of the season.
--
-- Tier: $500 maps to Blue (sponsorship_tiers 2026-27 Blue = 50000 cents),
-- confirmed against the live ladder rather than assumed. tier_id is resolved by
-- name at insert time, same pattern as migration 106, so no hardcoded uuid.
--
-- sort_order 7, appending after Mama Betty's Tex-Mex (6). Sponsors render in
-- sort_order within their tier, so this puts Freddie's last among the Blues.
--
-- website_url: https://freddiescarwash.com -- verified live (HTTP 200) before
-- writing this, per the rule set in 106 about not shipping a wrong link on a
-- paying sponsor. Real business, 2009 Wells Branch Pkwy in north Austin, which
-- is a few minutes from campus.
--
-- LOGO: sponsor-logos/freddies-carwash.png, already uploaded and verified
-- publicly readable (HTTP 200, 1200x1201 RGBA). Prep notes, because the source
-- was a 2-page 512pt Illustrator PDF and none of this is reproducible from the
-- filename alone:
--   * Both PDF pages are the same circular badge -- pixel-diffed them, max
--     channel difference 1, so page 1 was used and page 2 ignored.
--   * Rendered at 300dpi, trimmed to the artwork bbox, downscaled to 1200px
--     wide in RGB, and only THEN keyed white -> alpha, so the anti-aliased
--     edges pick up correct partial alpha instead of white fringing.
--   * Safe to key white here (unlike Capstone, where white was kept because its
--     mark is white-on-red): this badge is line art in black + teal with no
--     white-filled shapes, so nothing is lost.
--   * RGB snapped to a 3-colour palette (black / #0797B0 teal / white) to get
--     the file from 341KB down to 168KB, in line with the other logos. The mark
--     is flat colour with no gradients, so this is lossless in appearance.
--
-- Note the badge is SQUARE (1:1), unlike every other sponsor logo, which are
-- all wide. It will therefore render small: the Blue bounding box is
-- max-h-24/max-w-[200px] on /sponsors, so it lands ~96x96, and the homepage
-- strip caps non-MVP logos at max-h-12, so ~48x48 there. That is the tier
-- system working as designed, not a bug -- but if Freddie's ever asks why their
-- logo looks smaller than a Gold sponsor's, that is the reason.
--
-- Idempotent.

begin;

insert into sponsors (name, logo_url, website_url, tier_id, sort_order, year, active)
select 'Freddie''s Carwash',
       'freddies-carwash.png',
       'https://freddiescarwash.com',
       t.id,
       7,
       '2026-27',
       true
from sponsorship_tiers t
where t.year = '2026-27'
  and t.name = 'Blue'
  and t.active
  and not exists (
    select 1 from sponsors s
    where s.year = '2026-27' and s.name = 'Freddie''s Carwash'
  );

commit;
