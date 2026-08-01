-- 102_rollback.sql
-- Removes the three week-1 events seeded by 102. Safe to re-run.

begin;

delete from events
where slug in (
  'equipment-pickup-aug-3-2026',
  'upperclassmen-intra-squad-scrimmage-2026',
  'freshman-intra-squad-scrimmage-2026'
);

commit;
