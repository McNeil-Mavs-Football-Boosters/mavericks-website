-- 222_whatakick_signup_455.sql
-- WhataKick signup table 5:25 -> 4:55 PM. Jeremy 2026-09-28: "move all times by
-- 1/2 hour just like the game." Kendra's 5:25 was built around her 6:00 kickoff;
-- kickoff is 5:30 (219), so every clock time shifts 30 minutes earlier. The only
-- other clock time in the copy is kickoff itself, already 5:30.
-- Rollback: 222_rollback.sql
begin;
do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'whatakick-challenge-2026-10-01' and description like '%beginning at 5:25 PM%';
  if n <> 1 then raise exception 'expected the 5:25 description (found %, already applied?)', n; end if;
end $$;
update events
   set description = replace(description, 'beginning at 5:25 PM', 'beginning at 4:55 PM'), updated_at = now()
 where slug = 'whatakick-challenge-2026-10-01';
do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'whatakick-challenge-2026-10-01'
     and description like '%beginning at 4:55 PM%' and description not like '%5:25%'
     and description like '%Kickoff is 5:30 PM%';
  if n <> 1 then raise exception 'description not as intended'; end if;
end $$;
commit;
