-- 112_rollback.sql
-- Reverses 112: removes the Freddie's Carwash sponsor row for 2026-27.
--
-- Deletes the row rather than deactivating it, because unlike Rudy's (see 111)
-- there is nothing to hold in reserve here -- if this is being rolled back it is
-- because the row was wrong. The logo object sponsor-logos/freddies-carwash.png
-- is intentionally left in the bucket; storage is cheap and re-uploading it
-- means redoing the PDF prep documented in 112.

begin;

delete from sponsors
where year = '2026-27'
  and name = 'Freddie''s Carwash';

commit;
