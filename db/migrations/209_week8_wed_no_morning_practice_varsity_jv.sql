-- 209_week8_wed_no_morning_practice_varsity_jv.sql
--
-- Varsity and JV: NO early-morning practice on Wednesday Sep 23. Period 2/6
-- and the 10:45 a.m. flex stay as published. Freshmen are unchanged.
--
-- Source: Jeremy, Tue 2026-09-22 evening, relaying Coach: "JV and Varsity...
-- they do not have practice tomorrow morning. they will still be in flex and
-- period. freshmen stays the same."
--
-- ── WHAT CHANGES, ONE DAY BLOCK IN TWO ROWS ──
-- 202 published Coach's doc for Wednesday as 5:40 arrival / 6:00 ready /
-- 6:05-8:10 practice / Period 2/6 / 10:45 flex out for film / team dinner.
-- The three morning lines go; the block takes the same "**No morning
-- practice.**" opener Thursday and Friday already use; Period 2/6, the 10:45
-- flex line and the team dinner line are kept verbatim. The day heading keeps
-- "JV game day" because the JV game is still Wednesday.
--
-- This is a verbal relay overriding Coach's published weekly doc, which 120's
-- standing rule says the doc normally outranks. It is taken anyway because it
-- comes from Coach through Jeremy the evening before, cancels rather than
-- moves a session, and the failure mode is arriving at 5:40 to find nobody
-- there, not missing a practice. The body says the change came in Tuesday
-- evening so a reader comparing it to Coach's graphic knows which is newer.
--
-- Same fact elsewhere (176 rule): the 9/21 newsletter does not mention the
-- Wednesday 5:40 session; nothing else on the site carries it. `games` is not
-- touched. Freshman body is not touched and the verify block asserts its
-- Wednesday 8:00/8:25 lines survive.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.
--
-- Rollback: 209_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like '%## Week 8 — September 21–25%'
     and body like E'%### Wednesday, Sep 23 — JV game day\n- **5:40 a.m.** — Arrival\n- **6:00 a.m.** — Ready on the field\n- **6:05–8:10 a.m.** — Practice\n- Period 2/6\n- **10:45 a.m.** — Flex out for film\n%';
  if n <> 2 then raise exception 'expected 2 varsity/jv Week 8 bodies with the Wednesday morning block, found % (already applied?)', n; end if;
end $$;

update practice_schedules
   set body = replace(body,
       E'### Wednesday, Sep 23 — JV game day\n- **5:40 a.m.** — Arrival\n- **6:00 a.m.** — Ready on the field\n- **6:05–8:10 a.m.** — Practice\n- Period 2/6\n- **10:45 a.m.** — Flex out for film\n',
       E'### Wednesday, Sep 23 — JV game day\n**No morning practice.** (Changed by Coach Tuesday evening; his published schedule had a 5:40 a.m. session.)\n- Period 2/6\n- **10:45 a.m.** — Flex out for film\n'),
       updated_at = now()
 where year = '2026-27' and team_level in ('varsity','jv');

do $$
declare n int;
begin
  -- Both rows now say no morning practice Wednesday, keep period + flex + dinner, and
  -- 5:40 survives only inside the parenthetical note (Tuesday's 5:40 block is a
  -- different line and must still be there).
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like E'%### Wednesday, Sep 23 — JV game day\n**No morning practice.**%'
     and body like E'%### Wednesday, Sep 23 — JV game day\n**No morning practice.**%- Period 2/6\n- **10:45 a.m.** — Flex out for film\n- **Varsity team dinner**%'
     and body not like E'%### Wednesday, Sep 23 — JV game day\n- **5:40 a.m.**%'
     and body like E'%### Tuesday, Sep 22\n- **5:40 a.m.** — Arrival\n- **6:00 a.m.** — Ready on the field\n- **6:05–8:10 a.m.** — Practice%';
  if n <> 2 then raise exception 'varsity/jv Wednesday block not as intended (%)', n; end if;

  -- Thursday/Friday untouched.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity','jv')
     and body like E'%### Thursday, Sep 24 — varsity game day\n**No morning practice.**\n- Period 2/6%'
     and body like E'%### Friday, Sep 25\n**No morning practice.**\n- Period 2/6%';
  if n <> 2 then raise exception 'Thursday/Friday blocks disturbed (%)', n; end if;

  -- Freshmen untouched: Wednesday 8:00 / 8:25-9:25 still there, no varsity text.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like E'%### Wednesday, Sep 23 — game day\n- **8:00 a.m.** — Arrival\n- **8:25–9:25 a.m.** — Practice%'
     and body not like '%No morning practice%';
  if n <> 1 then raise exception 'freshman body was disturbed'; end if;
end $$;

commit;
