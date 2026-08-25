-- 161_rollback.sql
begin;

delete from resource_links
where label in ('Subscribe to Mav Mail', 'Buy Football Tickets');

update resource_links
set label = 'MavMail', description = null
where section = 'communications'
  and label = 'McNeil Live Feed'
  and url = 'https://mcneil.roundrockisd.org/o/mcneil/live-feed';

alter table games  drop column if exists ticket_url;
alter table venues drop column if exists ticket_url;

commit;
