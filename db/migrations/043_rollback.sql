-- 043_rollback.sql
-- Re-inserts the 3 sponsor_spotlight hero tiles removed by 043.
-- Same payloads as migration 041; sort_orders 101-103.

begin;

insert into hero_foreground_tiles (tile_type, payload, sort_order, active) values
  ('sponsor_spotlight',
   '{"sponsor_name":"Rudy''s BBQ","logo_bucket":"sponsor-logos","logo_storage_path":"rudys-bbq.png","tagline":null,"website_url":"https://rudysbbq.com"}'::jsonb,
   101, true),
  ('sponsor_spotlight',
   '{"sponsor_name":"AutoNation Chevrolet West Austin","logo_bucket":"sponsor-logos","logo_storage_path":"autonation-chevrolet-west-austin.png","tagline":null,"website_url":"https://www.autonationchevroletwestaustin.com"}'::jsonb,
   102, true),
  ('sponsor_spotlight',
   '{"sponsor_name":"Sunflower Bank","logo_bucket":"sponsor-logos","logo_storage_path":"sunflower-bank.png","tagline":null,"website_url":"https://www.sunflowerbank.com"}'::jsonb,
   103, true);

commit;
