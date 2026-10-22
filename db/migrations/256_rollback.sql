-- 256_rollback.sql
begin;
update events
   set description = replace(description,
         'Registration is $10 plus Eventbrite fees and includes',
         'Registration is $10 plus Eventbrite fees and closes Wednesday, October 21. It includes'),
       updated_at = now()
 where slug = 'homecoming-tunnel-stampede-2026';
commit;
