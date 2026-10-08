-- 231_rollback.sql -- reverses 231's player changes. 232 must be rolled back first
-- if the PDFs were repointed.
begin;

delete from players p using rosters r
 where r.id = p.roster_id and r.year = '2026-27' and r.team_level = 'varsity'
   and (p.jersey_number, p.first_name, p.last_name) in (('42','Bryan','Harris'), ('46','Ollie','Weisbrod'));
delete from players p using rosters r
 where r.id = p.roster_id and r.year = '2026-27' and r.team_level = 'jv'
   and p.jersey_number is null and (p.first_name, p.last_name) in (('Owen','Clark Richardson'), ('Jackson','Henry Miller'));
delete from players p using rosters r
 where r.id = p.roster_id and r.year = '2026-27' and r.team_level = 'freshman'
   and p.jersey_number = '34' and p.last_name = 'Jenkins';

insert into players (roster_id, jersey_number, first_name, last_name, position, grade, sort_order, active)
select r.id, v.j, v.f, v.l, v.pos, null, 0, true
  from rosters r,
       (values ('0','Antonio','Showels','RB'), ('4','Jake','Thomas','WR'), ('7','Krishman','Hoff','WR'),
               ('11','Case','Keough','DB'), ('12','Lamonte','Brown','RB'), ('14','Rashawn','Mcdowell','WR'),
               ('22','Byron','Deleon','WR'), ('52','Caleb','Woodward','OL'), ('53','Patrick','Hernadez','OL'),
               ('77','Jadien','Harris','OL'), ('88','Josiah','Harris','WR')) as v(j, f, l, pos)
 where r.year = '2026-27' and r.team_level = 'jv' and r.team_designation is null;

update players p set position = v.pos, updated_at = now()
  from rosters r, (values ('8','RB/K'), ('51','OL/DL'), ('64','OL/DL'), ('75','OL')) as v(j, pos)
 where r.id = p.roster_id and r.year = '2026-27' and r.team_level = 'jv' and p.jersey_number = v.j;
update players p set grade = null, updated_at = now()
  from rosters r where r.id = p.roster_id and r.year = '2026-27' and r.team_level = 'jv';

with ordered as (
  select p.id, row_number() over (partition by r.id order by split_part(p.jersey_number, '/', 1)::int, p.sort_order) as rn
    from players p join rosters r on r.id = p.roster_id
   where r.year = '2026-27'
)
update players p set sort_order = o.rn, updated_at = now()
  from ordered o where o.id = p.id and p.sort_order is distinct from o.rn;

update rosters set source_note = regexp_replace(source_note, '; revised (export|roster) received 2026-10-08 \([^)]*\)$', ''), updated_at = now()
 where year = '2026-27';

commit;
