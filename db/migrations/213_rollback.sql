-- 213_rollback.sql: restores the pre-213 photo URLs and removes Texada.
begin;
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/JerryGardner.png', updated_at = now() where year = '2026-27' and active and name = 'Jerry Gardner';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachGillisHead.jpg', updated_at = now() where year = '2026-27' and active and name = 'Alexander Gillis';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachHaleHead.jpg', updated_at = now() where year = '2026-27' and active and name = 'Michael Hale';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachMatthewsHead.jpg', updated_at = now() where year = '2026-27' and active and name = 'Barrett Matthews';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachWallinHead.jpg', updated_at = now() where year = '2026-27' and active and name = 'Douglas Wallin';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachDeboseHead.jpg', updated_at = now() where year = '2026-27' and active and name = 'Reginal Debose';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachEdwardsHead.jpg', updated_at = now() where year = '2026-27' and active and name = 'Nick Edwards';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachWard.jpg', updated_at = now() where year = '2026-27' and active and name = 'Justin Ward';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachUmbergerHead.jpg', updated_at = now() where year = '2026-27' and active and name = 'Thomas Umberger';
update coaches set photo_url = null, updated_at = now() where year = '2026-27' and active and name = 'Ryan Doyle';
update coaches set photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachJonesHead.jpg', updated_at = now() where year = '2026-27' and active and name = 'Devonte Jones';
delete from coaches where year = '2026-27' and name = 'Raleigh Texada';
commit;
