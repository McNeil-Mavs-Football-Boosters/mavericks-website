-- 169_whataburger_supplied_logo.sql
--
-- Whataburger sent real artwork. Jeremy 2026-08-27. Swap their sponsor logo
-- from the stand-in 164 shipped to the file they supplied.
--
--   whataburger.png     -> whataburger-r2.png
--
-- ── WHY THIS IS AN UPGRADE, NOT A LATERAL MOVE ──
-- 164 could not use what was supplied at the time (a 77x75 all-WHITE nav asset,
-- invisible on a white card) and shipped Whataburger's own current lockup from
-- Wikimedia Commons instead. That was the right call then and it is superseded
-- now. The new file is better on three counts, each checked rather than assumed:
--   1. It is THEIR file, not a third-party reconstruction.
--   2. The orange is #F58220, their actual brand colour. The Commons rendering
--      was #FF770F -- brighter and redder, visibly off beside it.
--   3. It carries BOTH registration marks (the W and the wordmark). The Commons
--      version has only the W's.
--
-- ⚠️ It is 360x346 where the old file was 1200x1133, and that is FINE, not a
-- regression to fix. Gold renders at `max-h-32 max-w-[min(280px,100%)]`, so this
-- mark displays about 133x128 -- roughly 2.7x for retina. **Do NOT upscale it to
-- match the 1200px convention**; `crop_and_scale` in prep_gold_2026_08.py aborts
-- rather than upscale for exactly this reason, and enlarging a raster would
-- trade real sharpness for a number in a filename. If a vector ever arrives,
-- that is the upgrade worth taking.
--
-- ── 🚨 WHY A NEW FILENAME INSTEAD OF OVERWRITING whataburger.png ──
-- **Replacing an object at the same storage path serves the OLD bytes for up to
-- 31 days.** Every Supabase Storage object serves `cache-control: no-cache`,
-- which is a platform override we cannot change, so Next's image optimiser falls
-- back to its own TTL and there is no invalidation mechanism. Overwriting would
-- have looked like it worked locally and shown the old logo on the live site for
-- a month. The documented workaround is a new path plus a row update -- the same
-- reason the varsity roster PDF is `varsity-2026-r2.pdf`.
--
-- 🚫 DO NOT DELETE `whataburger.png` from the bucket. Storage is not
-- transactional with the database, 169_rollback points back at it, and an orphan
-- PNG costs nothing.
--
-- No transformation was applied to the supplied file. It arrived already tightly
-- cropped to its ink, transparent, and a single flat colour -- all three asserted
-- before upload -- so it is byte-identical to what they sent (sha256 verified
-- against the local copy and the public URL after the round trip). Pinned at
-- partner_logos/sources/gold-2026-08/whataburger-SUPPLIED-orangewset.png.
--
-- Tier, sort_order, website_url and everything else are untouched: this is one
-- column on one row.
--
-- DB-ONLY, NO DEPLOY. All three sponsor surfaces read at request time except the
-- homepage strip, which is ISR revalidate=60 and lags about a minute.

begin;

update sponsors
set logo_url = 'whataburger-r2.png'
where year = '2026-27' and name = 'Whataburger' and kind = 'sponsor';

do $$
declare n int;
begin
  select count(*) into n from sponsors s
   join sponsorship_tiers t on t.id = s.tier_id
   where s.year = '2026-27' and s.name = 'Whataburger'
     and s.logo_url = 'whataburger-r2.png'
     and t.name = 'Gold' and s.active and s.kind = 'sponsor';
  if n <> 1 then
    raise exception 'Whataburger logo not updated as expected (matched % rows)', n;
  end if;

  -- Nothing else may point at the retired file, and nothing else may have moved.
  select count(*) into n from sponsors
   where year = '2026-27' and logo_url = 'whataburger.png';
  if n <> 0 then raise exception '% rows still reference the old file', n; end if;

  select count(*) into n from sponsors where year = '2026-27' and kind = 'sponsor' and active;
  if n <> 18 then raise exception 'paid sponsor count changed: %', n; end if;

  select count(*) into n from sponsors
   where year = '2026-27' and kind = 'sponsor' and name = 'Whataburger' and sort_order = 13;
  if n <> 1 then
    raise exception 'Whataburger sort_order moved; a logo swap must not reorder anything';
  end if;
end $$;

commit;
