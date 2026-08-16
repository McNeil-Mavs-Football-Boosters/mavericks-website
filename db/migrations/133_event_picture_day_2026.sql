-- 133_event_picture_day_2026.sql
--
-- Football Picture Day, Friday August 21. Jeremy 2026-08-16, off Coach's weekly
-- schedule for Aug 17-23 (the same doc migration 129 published). It stays on the
-- practice pages as well - explicitly fine per Jeremy - because a family reading
-- Friday's practice block should not have to know to also check /events.
--
-- ONE EVENT, NOT TWO. The doc gives two different windows:
--     Upperclassmen  7:00 arrival -> 8:00 pictures complete, film during Period 2
--     Freshmen       8:00 arrival -> 9:15 pictures complete, film after if time
-- Seeded as a single 7:00-9:15 a.m. row with both windows spelled out in the
-- description, rather than two rows. Two rows would put two overlapping
-- "Picture Day" entries on every subscribed calendar and force every parent to
-- work out which one is theirs; one row with both times is unambiguous whichever
-- group you are in. This is the same call migration 102 made for the equipment
-- pickups, where both groups' times went in the description of a single row.
--
-- ⚠️ The 9:15 END is the freshmen "pictures complete" time, and the 7:00 START is
-- the upperclassmen arrival - i.e. the envelope of both groups, not one group's
-- window. Do not read the event's own times as any single athlete's call time;
-- that is what the description is for.
--
-- Location is the school, not the stadium: the doc gives no room and picture day
-- has historically been indoors. `location_url` is the same campus pin the Meet
-- the Mavs row uses (migration 108) rather than a new guess at a building.
--
-- August 2026 is CDT, hence -05.

begin;

insert into events (title, slug, description, starts_at, ends_at, location, location_url, status)
values (
  'Football Picture Day',
  'picture-day-2026',
  'Team and individual photos for all three levels. Upperclassmen (Soph/Jr/Sr): 7:00 a.m. arrival, pictures complete by 8:00 a.m., film during Period 2. Freshmen: 8:00 a.m. arrival, pictures complete by 9:15 a.m., film after pictures if time permits.',
  '2026-08-21 07:00:00-05',
  '2026-08-21 09:15:00-05',
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published'
)
on conflict (slug) do nothing;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'picture-day-2026' and status = 'published'
     and starts_at = '2026-08-21 07:00:00-05'::timestamptz
     and ends_at   = '2026-08-21 09:15:00-05'::timestamptz;
  if n <> 1 then raise exception 'picture-day-2026 not seeded as expected (matched % rows)', n; end if;
end $$;

commit;

-- /events reads at request time: live with no deploy.
