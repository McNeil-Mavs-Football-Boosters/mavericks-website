-- 159_rollback.sql
--
-- Restore the spreadsheet reading order that 157 assigned: down the rows,
-- taking the left block cell then the right block cell, so 0, 26, 1, 27, ...
--
-- ⚠️ Written as an explicit (jersey, sort_order) list, NOT derived. The
-- interleave is a property of the SOURCE SPREADSHEET's two-block layout and
-- cannot be recomputed from the table -- nothing in `players` records which
-- block a player came from. This list is the only place that order survives.

begin;

update players p
   set sort_order = v.sort_order
  from rosters r,
       (values
  ('0'    ,  1),
  ('26'   ,  2),
  ('1'    ,  3),
  ('27'   ,  4),
  ('3'    ,  5),
  ('28'   ,  6),
  ('4'    ,  7),
  ('29'   ,  8),
  ('5/2'  ,  9),
  ('30'   , 10),
  ('6'    , 11),
  ('32'   , 12),
  ('7'    , 13),
  ('33'   , 14),
  ('8/18' , 15),
  ('34'   , 16),
  ('9/10' , 17),
  ('35'   , 18),
  ('11'   , 19),
  ('38'   , 20),
  ('12'   , 21),
  ('40'   , 22),
  ('13'   , 23),
  ('51'   , 24),
  ('14'   , 25),
  ('52'   , 26),
  ('15'   , 27),
  ('55'   , 28),
  ('16'   , 29),
  ('61'   , 30),
  ('17'   , 31),
  ('64/65', 32),
  ('19'   , 33),
  ('66'   , 34),
  ('20'   , 35),
  ('71'   , 36),
  ('21'   , 37),
  ('72'   , 38),
  ('22'   , 39),
  ('75'   , 40),
  ('23'   , 41),
  ('76'   , 42),
  ('25'   , 43),
  ('84/80', 44),
  ('90'   , 45)
       ) as v(jersey_number, sort_order)
 where p.roster_id = r.id
   and r.year = '2026-27'
   and r.team_level = 'varsity'
   and r.team_designation is null
   and p.jersey_number = v.jersey_number;

commit;
