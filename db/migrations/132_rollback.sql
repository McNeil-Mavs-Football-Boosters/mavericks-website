-- 132_rollback.sql — puts the four Aug 20 Eastview rows back to no venue, the
-- state migration 130 left them in. Note that the Print View PDF names the venue
-- either way, so rolling this back reintroduces that mismatch.

begin;

update games
   set location = null
 where year = '2026-27'
   and opponent = 'Eastview High School'
   and location = 'Maverick Stadium';

commit;
