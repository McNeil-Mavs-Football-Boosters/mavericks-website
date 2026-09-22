-- 207_rollback.sql -- back to 206's pin and 205's note.
begin;
update venues
   set maps_url = 'https://www.google.com/maps/place/Lake+Travis+high+school+track+and+field/@30.3233705,-97.9717634,545m/data=!3m1!1e3!4m6!3m5!1s0x865b393fa1e37c57:0x4b0946098420898f!8m2!3d30.3235418!4d-97.9704399!16s%2Fg%2F11h7k2hrt5',
       latitude = 30.3235418, longitude = -97.9704399, updated_at = now()
 where name = 'Lake Travis Track Stadium';
update games set notes = 'Track stadium, not Cavalier Stadium', updated_at = now()
 where year = '2026-27' and team_level = 'jv'
   and game_date = timestamptz '2026-09-23 18:00 America/Chicago' and location = 'Lake Travis Track Stadium';
commit;
