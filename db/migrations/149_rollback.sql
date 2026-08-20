-- 149_rollback.sql — pulls the Picture Day ordering link back down and drops
-- the label column.
--
-- Order matters: restore the description BEFORE dropping the column, and match
-- on the appended sentence so a hand-edited description is left alone.

begin;

update events
set signup_url  = null,
    signup_label = null,
    description = 'Team and individual photos for all three levels. Upperclassmen (Soph/Jr/Sr): 7:00 a.m. arrival, pictures complete by 8:00 a.m., film during Period 2. Freshmen: 8:00 a.m. arrival, pictures complete by 9:15 a.m., film after pictures if time permits.'
where slug = 'picture-day-2026'
  and description like '%school photographer''s online gallery%';

-- Only drop the column if nothing else has come to depend on it. A later event
-- with its own label means this rollback would silently delete real content.
do $$
declare n int;
begin
  select count(*) into n from events where signup_label is not null;
  if n <> 0 then
    raise exception 'refusing to drop signup_label: % row(s) still set it', n;
  end if;
end $$;

alter table events drop column if exists signup_label;

commit;

-- To pull ONLY the link (keeping the column and the code), the whole rollback is:
--   update events set signup_url = null where slug = 'picture-day-2026';
