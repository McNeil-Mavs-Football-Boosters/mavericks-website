-- 162_rollback.sql -- restores McNeil's entity page on the RRISD venues.
begin;
update venues
set ticket_url = 'https://events.hometownticketing.com/boxoffice/roundrockisd/entity/schools/26'
where ticket_url = 'https://events.hometownticketing.com/boxoffice/roundrockisd';
commit;
