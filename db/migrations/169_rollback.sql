-- 169_rollback.sql — points Whataburger back at the Commons-sourced logo.
--
-- `whataburger.png` was deliberately left in the bucket by 169, so this needs no
-- re-upload. ⚠️ If somebody deleted it anyway, rebuild it with
-- `partner_logos/prep_gold_2026_08.py`, which still carries the Commons SVG as a
-- pinned source.
--
-- ⚠️ Expect the OLD image to keep serving for a while after this either way --
-- storage objects are cached hard and there is no invalidation. That is the same
-- constraint that made 169 use a new filename rather than overwrite.

begin;

update sponsors
set logo_url = 'whataburger.png'
where year = '2026-27' and name = 'Whataburger' and kind = 'sponsor';

do $$
declare n int;
begin
  select count(*) into n from sponsors
   where year='2026-27' and name='Whataburger' and logo_url='whataburger.png';
  if n <> 1 then raise exception 'Whataburger logo not reverted'; end if;
  select count(*) into n from sponsors where year='2026-27' and logo_url='whataburger-r2.png';
  if n <> 0 then raise exception '% rows still on the r2 file', n; end if;
end $$;

commit;
