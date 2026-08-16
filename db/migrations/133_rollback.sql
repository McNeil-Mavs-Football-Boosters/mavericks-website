-- 133_rollback.sql — removes the Picture Day event. The practice pages carry the
-- same times independently (migration 129), so nothing is lost from the site by
-- running this; only the calendar entry and its ICS feed line go away.

begin;

delete from events where slug = 'picture-day-2026';

commit;
