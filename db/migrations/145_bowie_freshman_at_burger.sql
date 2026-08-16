-- 145_bowie_freshman_at_burger.sql
--
-- ⚠️ PROVISIONAL - the least certain venue call in this whole series. Rolled
-- back with 145_rollback.sql alone if it turns out wrong.
--
-- Jeremy 2026-08-16: "Bowie plays at Berger [Burger] from what I can tell" -
-- his own words carry the hedge. What is on each side:
--
--   FOR Burger: Bowie is an Austin ISD school and AISD runs shared district
--   stadiums; published Bowie sub-varsity results show freshman and JV home
--   games at Burger Stadium. Our own varsity row for the very next night is
--   already 'Burger Stadium'.
--
--   AGAINST: the school's schedule PDF - and therefore our rows - says
--   'Bowie HS' for the freshman games and 'Burger Stadium' for varsity, on
--   consecutive days. Whoever typed it used two different strings 24 hours
--   apart, which is at least weak evidence they meant two different places.
--   Sub-varsity on campus with varsity at the district stadium is the normal
--   AISD pattern.
--
-- Resolution: attach the Burger pin (verified, from Jeremy's first link) because
-- it is more likely right than a campus address nobody has checked - but LEAVE
-- THE DISPLAY LABEL as 'Bowie HS'. That is deliberate:
--   * changing the label to 'Burger Stadium' would put the site back in
--     disagreement with the Print View PDF, the exact defect fixed hours earlier
--     on 2026-08-16, on the strength of a hedge;
--   * the label is what the school published, and it is not wrong that the game
--     is "at Bowie" in the sense of "against Bowie, at their home site";
--   * if this turns out to be the campus after all, only the pin is wrong and it
--     is one statement to fix.
--
-- ⚠️ THE LABEL AND THE PIN THEREFORE DISAGREE for these two rows: the page reads
-- "Bowie HS" and links to Burger Stadium, ~8 miles apart. That is a real, visible
-- inconsistency and it is being carried ON PURPOSE pending confirmation. Jeremy
-- has been asked to confirm with Coach or Bowie athletics. Once confirmed:
--   * if Burger - set location = 'Burger Stadium' on these two rows AND patch the
--     freshman Aug. 27 row in the Print View PDF
--     (MavericksWebsite/scripts/patch-schedule-pdf-scrimmages.py), so all three
--     surfaces agree;
--   * if campus - run 145_rollback.sql and get a pin for the Bowie field.
-- Do not let this sit unresolved past Aug 27, when the game is played.

begin;

update games
   set venue_id = (select id from venues where name = 'Toney Burger Stadium')
 where location = 'Bowie HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.location = 'Bowie HS' and v.name = 'Toney Burger Stadium';
  if n <> 2 then raise exception 'expected 2 Bowie freshman games at Burger, got %', n; end if;

  -- Every 2026-27 game now sits at a venue with a verified pin.
  select count(*) into n from games g left join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.location is not null
     and (v.id is null or v.latitude is null);
  if n <> 0 then raise exception '% 2026-27 games still lack a verified pin', n; end if;
end $$;

commit;
