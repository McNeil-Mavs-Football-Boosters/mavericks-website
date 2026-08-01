-- 102_events_week1_scrimmages_equipment.sql
--
-- Surfaces the week-1 items from Coach's Aug 3-9 doc on /events. The Pool Party
-- (Aug 7) is already seeded by migration 059; these are the three that were
-- only visible on the practice pages.
--
-- One equipment-pickup row, not two: unlike the 7/29 and 7/30 pickups seeded by
-- migration 071 (different days, different groups), both groups collect on the
-- same morning, so two same-day rows for one activity would just read as
-- duplicates. Both times are in the description.
--
-- ends_at is NULL on the pickup: Coach's doc gives designated start times
-- (6:45 a.m. / 9:20 a.m.) with no stated close, and the senior-photo-shoot row
-- from migration 070 sets the same precedent. Not inventing an end time.
--
-- August 2026 is CDT, hence the -05 offsets.

begin;

insert into events (title, slug, description, starts_at, ends_at, location, status)
values
  (
    'Equipment Pickup - Players Who Still Need Equipment',
    'equipment-pickup-aug-3-2026',
    'For players who still need to be issued equipment before the first week of practice. Upperclassmen (Soph / Jr / Sr) at 6:45 a.m., ahead of the 7:10 a.m. arrival time. Freshmen at 9:20 a.m., ahead of the 10:00 a.m. warm-up. Players already issued equipment do not need to come early.',
    '2026-08-03 06:45:00-05',
    null,
    'McNeil High School',
    'published'
  ),
  (
    'Upperclassmen Intra-Squad Scrimmage',
    'upperclassmen-intra-squad-scrimmage-2026',
    'Soph / Jr / Sr intra-squad scrimmage closing out week 1. Arrival 6:45 a.m., warm-up begins on the field at 7:00 a.m., scrimmage 7:30-8:30 a.m. The freshman scrimmage follows at 9:00 a.m.',
    '2026-08-08 07:30:00-05',
    '2026-08-08 08:30:00-05',
    'McNeil High School',
    'published'
  ),
  (
    'Freshman Intra-Squad Scrimmage',
    'freshman-intra-squad-scrimmage-2026',
    'Freshman intra-squad scrimmage closing out week 1. Arrival 8:30 a.m., warm-up begins on the field at 8:45 a.m., scrimmage 9:00-10:00 a.m. The upperclassmen scrimmage runs earlier the same morning at 7:30 a.m.',
    '2026-08-08 09:00:00-05',
    '2026-08-08 10:00:00-05',
    'McNeil High School',
    'published'
  )
on conflict (slug) do nothing;

commit;
