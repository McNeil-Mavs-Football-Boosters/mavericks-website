-- 131_rollback.sql — pulls the Meet the Mavs album back off the site. The album
-- itself is untouched; only the public link to it goes away, and both render
-- sites hide their affordance when photos_url is null.

begin;

update events
   set photos_url = null
 where slug = 'meet-the-mavs-2026';

commit;
