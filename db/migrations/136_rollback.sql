-- 136_rollback.sql — back to migration 134's address-search link and the
-- Prairie View Road spelling. Only useful if the pin turns out to be wrong;
-- the state it restores is known-bad (road centerline, 920 m off).

begin;

update venues
   set maps_url = 'https://maps.google.com/?q=9809+Prairie+View+Road+Temple+TX+76502',
       address  = '9809 Prairie View Road, Temple, TX 76502',
       updated_at = now()
 where name = 'Lake Belton High School';

commit;
