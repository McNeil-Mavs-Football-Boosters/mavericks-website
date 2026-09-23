-- 209_rollback.sql
--
-- Restores the Wednesday Sep 23 early-morning block (5:40 / 6:00 / 6:05-8:10)
-- in the varsity and JV Week 8 bodies, exactly as 202 wrote it. Freshmen were
-- never touched.

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like E'%### Wednesday, Sep 23 — JV game day\n**No morning practice.** (Changed by Coach Tuesday evening; his published schedule had a 5:40 a.m. session.)\n- Period 2/6\n%';
  if n <> 2 then raise exception 'expected 2 bodies with the 209 Wednesday block, found % (209 not applied?)', n; end if;
end $$;

update practice_schedules
   set body = replace(body,
       E'### Wednesday, Sep 23 — JV game day\n**No morning practice.** (Changed by Coach Tuesday evening; his published schedule had a 5:40 a.m. session.)\n- Period 2/6\n- **10:45 a.m.** — Flex out for film\n',
       E'### Wednesday, Sep 23 — JV game day\n- **5:40 a.m.** — Arrival\n- **6:00 a.m.** — Ready on the field\n- **6:05–8:10 a.m.** — Practice\n- Period 2/6\n- **10:45 a.m.** — Flex out for film\n'),
       updated_at = now()
 where year = '2026-27' and team_level in ('varsity','jv');

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like E'%### Wednesday, Sep 23 — JV game day\n- **5:40 a.m.** — Arrival\n- **6:00 a.m.** — Ready on the field\n- **6:05–8:10 a.m.** — Practice\n- Period 2/6\n%';
  if n <> 2 then raise exception 'rollback did not restore both rows (%)', n; end if;
end $$;

commit;
