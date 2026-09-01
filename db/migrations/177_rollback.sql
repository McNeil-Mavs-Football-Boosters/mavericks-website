-- 177_rollback.sql — puts the Sep 4 varsity home opener back at Dragon Stadium.
-- ⚠️ Also roll back 178 (the PDF repoint) or the printed schedule and the site
-- will disagree again.

begin;

update games
   set location = 'Dragon Stadium',
       venue_id = (select id from venues where name = 'Round Rock High School Dragon Stadium'),
       updated_at = now()
 where id = '929405f5-70be-449f-80a2-8abd9e586ee4';

commit;
