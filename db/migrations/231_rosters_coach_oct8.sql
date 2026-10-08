-- 231_rosters_coach_oct8.sql
--
-- Coach Gardner's three rosters, emailed to Jeremy Thu 2026-10-08. Applied as a
-- DIFF against the live rows, not a replace (Jeremy: "do not do a full replace").
--
-- VARSITY 49 -> 51. Two adds, both JV linebackers playing up (183's rule, do
-- NOT deduplicate against their JV rows):
--   #42 Bryan Harris LB Jr.   (export "Brian"; JV row is Bryan Neal II Harris)
--   #46 Ollie Weisbrod LB Jr. (export "Weisbroad"; JV row is Oliver Douglas Weisbrod)
--   Spellings per Jeremy 2026-10-08. The export still carries Elanssari,
--   Southernland, "Amery A." and Galaza; the site keeps El Anssari, Sutherland,
--   Amery, Galarza (228/230). Export also has an empty #29 row; ignored.
--
-- JV 32 -> 23. Coach sent names/positions/class but NO numbers ("use the
-- current numbers", Jeremy). 21 match live by name; 11 removed (DELETE, not
-- deactivate, per 201; every row is in 231_rollback): #0 Showels (stays varsity
-- #15), #4 Jake Thomas, #7 Hoff, #11 Keough, #12 Lamonte Brown, #14 Mcdowell,
-- #22 Deleon, #52 Woodward, #53 Hernadez, #77 Jadien Harris, #88 Josiah Harris.
-- Two adds with NO number (Jeremy: add now, number when Coach sends it):
-- Owen Clark Richardson DL So., Jackson Henry Miller DL Jr. Name split follows
-- the JV seed (first word = first_name, rest = last_name).
-- Positions: Soto RB/K -> DB/K, Fabien OL/DL -> DL, Pelosi OL/DL -> DL/OL,
-- Faulkner OL -> DL/OL. Grades filled from Coach's class column (10 So., 11 Jr.);
-- every JV grade was NULL before.
--
-- FRESHMAN 50 -> 51. One add: #34 Jarrell Jenkins. Everything else matches.
--
-- PDFs are NOT repointed here; 232 does that after the new files are uploaded.
-- DB-ONLY, NO DEPLOY. Rollback: 231_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity';
  if n <> 49 then raise exception 'varsity is % rows, expected 49 (already applied?)', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'jv';
  if n <> 32 then raise exception 'jv is % rows, expected 32 (already applied?)', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'freshman' and r.team_designation = 'Green';
  if n <> 50 then raise exception 'freshman is % rows, expected 50 (already applied?)', n; end if;
end $$;

-- ── VARSITY ──
insert into players (roster_id, jersey_number, first_name, last_name, position, grade, sort_order, active)
select r.id, v.j, v.f, v.l, 'LB', 'Jr.', 0, true
  from rosters r,
       (values ('42','Bryan','Harris'), ('46','Ollie','Weisbrod')) as v(j, f, l)
 where r.year = '2026-27' and r.team_level = 'varsity' and r.team_designation is null;

with ordered as (
  select p.id, row_number() over (order by split_part(p.jersey_number, '/', 1)::int, p.sort_order) as rn
    from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
)
update players p set sort_order = o.rn, updated_at = now()
  from ordered o where o.id = p.id and p.sort_order is distinct from o.rn;

update rosters
   set source_note = source_note || '; revised export received 2026-10-08 (#42 Bryan Harris, #46 Ollie Weisbrod added)',
       updated_at = now()
 where year = '2026-27' and team_level = 'varsity' and team_designation is null;

-- ── JV ──
delete from players p using rosters r
 where r.id = p.roster_id and r.year = '2026-27' and r.team_level = 'jv'
   and (p.jersey_number, p.first_name, p.last_name) in
       (('0','Antonio','Showels'), ('4','Jake','Thomas'), ('7','Krishman','Hoff'),
        ('11','Case','Keough'), ('12','Lamonte','Brown'), ('14','Rashawn','Mcdowell'),
        ('22','Byron','Deleon'), ('52','Caleb','Woodward'), ('53','Patrick','Hernadez'),
        ('77','Jadien','Harris'), ('88','Josiah','Harris'));

insert into players (roster_id, jersey_number, first_name, last_name, position, grade, sort_order, active)
select r.id, null, v.f, v.l, 'DL', v.g, 0, true
  from rosters r,
       (values ('Owen','Clark Richardson','So.'), ('Jackson','Henry Miller','Jr.')) as v(f, l, g)
 where r.year = '2026-27' and r.team_level = 'jv' and r.team_designation is null;

update players p set position = v.pos, updated_at = now()
  from rosters r, (values ('8','DB/K'), ('51','DL'), ('64','DL/OL'), ('75','DL/OL')) as v(j, pos)
 where r.id = p.roster_id and r.year = '2026-27' and r.team_level = 'jv' and p.jersey_number = v.j;

update players p set grade = case when p.jersey_number in
         ('5','8','13','17','33','56','64','67','68','75','84') then 'So.' else 'Jr.' end,
       updated_at = now()
  from rosters r
 where r.id = p.roster_id and r.year = '2026-27' and r.team_level = 'jv' and p.jersey_number is not null;

-- numbered players in jersey order, then the two without numbers by last name
with ordered as (
  select p.id, row_number() over (order by p.jersey_number is null, nullif(p.jersey_number,'')::int, p.last_name) as rn
    from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'jv'
)
update players p set sort_order = o.rn, updated_at = now()
  from ordered o where o.id = p.id and p.sort_order is distinct from o.rn;

update rosters
   set source_note = source_note || '; revised roster received 2026-10-08 (11 removed, Richardson and Miller added, numbers pending)',
       updated_at = now()
 where year = '2026-27' and team_level = 'jv' and team_designation is null;

-- ── FRESHMAN ──
insert into players (roster_id, jersey_number, first_name, last_name, position, grade, sort_order, active)
select r.id, '34', 'Jarrell', 'Jenkins', null, null, 0, true
  from rosters r
 where r.year = '2026-27' and r.team_level = 'freshman' and r.team_designation = 'Green';

with ordered as (
  select p.id, row_number() over (order by p.jersey_number::int) as rn
    from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'freshman' and r.team_designation = 'Green'
)
update players p set sort_order = o.rn, updated_at = now()
  from ordered o where o.id = p.id and p.sort_order is distinct from o.rn;

update rosters
   set source_note = source_note || '; revised roster received 2026-10-08 (#34 Jenkins added)',
       updated_at = now()
 where year = '2026-27' and team_level = 'freshman' and team_designation = 'Green';

-- ── POST-CHECKS ──
do $$
declare n int;
begin
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity';
  if n <> 51 then raise exception 'varsity is %, expected 51', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'jv';
  if n <> 23 then raise exception 'jv is %, expected 23', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'jv' and (p.grade is null or p.position is null);
  if n <> 0 then raise exception '% jv rows missing grade/position', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'freshman' and r.team_designation = 'Green';
  if n <> 51 then raise exception 'freshman is %, expected 51', n; end if;
  -- the four spelling overrides survive
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and p.last_name in ('El Anssari','Sutherland','Galarza') ;
  if n <> 3 then raise exception 'override spellings missing (%)', n; end if;
  select count(*) into n from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27' and r.team_level = 'varsity'
     and (p.last_name in ('Elanssari','Southernland','Galaza','Weisbroad')
          or p.first_name in ('Brian','Amery A.'));
  if n <> 0 then raise exception 'export misspelling reached the DB (%)', n; end if;
  -- dense sort_order on all three
  select count(*) into n from (
    select r.id, count(*) c, count(distinct p.sort_order) d, max(p.sort_order) m
      from players p join rosters r on r.id = p.roster_id
     where r.year = '2026-27' group by r.id) t where not (c = d and d = m);
  if n <> 0 then raise exception 'sort_order not dense on % rosters', n; end if;
end $$;

commit;
