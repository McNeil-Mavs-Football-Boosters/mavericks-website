-- 215_senior_night_locker_decorating.sql
--
-- Senior Night locker decorating, as a volunteer event on /events. Jeremy
-- 2026-09-23: "add this as an event for people to sign up for to help", with
-- Shannon's SignUpGenius:
--   https://www.signupgenius.com/go/60B084CA4AC2DA6FB6-66102591-senior#/
-- (the 9/22 minutes: "locker decorating Thu Oct 8 via Shannon's SignUpGenius
-- (Jeremy posts)"). This is that post.
--
-- ── FACTS, ALL FROM THE SIGNUPGENIUS PAGE (og:description read 9/23 10:30 AM) ──
--   * Title "Senior Night - Decorate Locker Room", author McNeil Football Booster Club.
--   * Thursday, October 8, 2026, 6:00 to 8:00 pm, "during and after the Freshman game".
--     Checked against `games`: the freshman Green team hosts Stony Point at
--     Maverick Stadium at 6:30 that night (JV is away at Stony Point), so the
--     window and the venue agree with the schedule. No other `events` row on Oct 8.
--   * McNeil High School Varsity Locker Room; enter near the locker rooms on the
--     east side of the building, signs will direct.
--   * Senior parents may bring personalised decorations (collages, notes).
--   * "Please comment on your SignUp with your player's name and number."
--   * Supplies or money donations also welcome (Venmo / PayPal handles on the page).
--
-- ── SHAPE ──
-- Same columns as the other McNeil-campus events (parent-athlete-meeting-2026,
-- mavs-and-moms-senior-photo-day-2026): venue_id = the existing "McNeil High
-- School" venue row, `location` = the room. `signup_url` is the SignUpGenius
-- link exactly as Jeremy pasted it; `signup_label` left null so the button
-- reads the default "Sign Up ->", which is accurate here (unlike 211).
--
-- ⚠️ THE VENMO / PAYPAL HANDLES ARE NOT RESTATED IN THE DESCRIPTION, following
-- 059 (pool party): payment handles live on the signup page, one place to fix.
-- The description says donations are welcome and points at the signup.
--
-- ⚠️ QUESTIONS GO TO boosters@mcneilmavericks.org, the club address this site
-- publishes everywhere, not the gmail the SignUpGenius names. Both reach the
-- booster inbox; the site does not print the gmail anywhere and should not
-- start here.
--
-- Slug carries the date and will not be renamed if the date moves (194's rule).
-- DB-ONLY, NO DEPLOY. Rollback: 215_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from events where slug = 'senior-night-locker-decorating-2026-10-08';
  if n <> 0 then raise exception 'event already exists (found %)', n; end if;

  select count(*) into n from events where starts_at::date = date '2026-10-08';
  if n <> 0 then raise exception '% events already sit on Oct 8', n; end if;

  select count(*) into n from venues where name = 'McNeil High School';
  if n <> 1 then raise exception 'expected exactly one McNeil High School venue, found %', n; end if;

  -- The freshman game the window is built around.
  select count(*) into n from games
   where team_level = 'freshman' and home_or_away = 'home'
     and game_date = timestamptz '2026-10-08 18:30 America/Chicago';
  if n < 1 then raise exception 'no 6:30 home freshman game on Oct 8 in games; check before publishing "during the freshman game"'; end if;
end $$;

insert into events (title, slug, description, starts_at, ends_at, location, venue_id, signup_url, status)
select
  'Senior Night: Decorate the Varsity Locker Room',
  'senior-night-locker-decorating-2026-10-08',
  'Help make Senior Night special. We will decorate the senior players'' lockers in the varsity locker room ahead of the Senior Night varsity game on Friday, October 9. Thursday, October 8, 6:00 to 8:00 PM, during and after the freshman game. McNeil High School varsity locker room: enter near the locker rooms on the east side of the building, and signs will direct you. Parents of seniors, feel free to bring personalized decorations for your player, like picture collages and handwritten notes. When you sign up, please add a comment with your player''s name and number so we know who is coming. Cannot make it? Supplies and donations toward decorations are welcome too, details on the signup page. Questions: boosters@mcneilmavericks.org.',
  timestamptz '2026-10-08 18:00 America/Chicago',
  timestamptz '2026-10-08 20:00 America/Chicago',
  'McNeil High School Varsity Locker Room',
  v.id,
  'https://www.signupgenius.com/go/60B084CA4AC2DA6FB6-66102591-senior#/',
  'published'
from venues v where v.name = 'McNeil High School';

do $$
declare n int;
begin
  select count(*) into n from events e join venues v on v.id = e.venue_id
   where e.slug = 'senior-night-locker-decorating-2026-10-08'
     and e.status = 'published'
     and v.name = 'McNeil High School'
     and e.signup_url like 'https://www.signupgenius.com/go/60B084CA4AC2DA6FB6-66102591-senior%'
     and e.signup_label is null
     and extract(hour from e.starts_at at time zone 'America/Chicago') = 18
     and extract(hour from e.ends_at   at time zone 'America/Chicago') = 20
     and e.description like '%Thursday, October 8, 6:00 to 8:00 PM%'
     and e.description like '%player''s name and number%'
     and e.description not like '%Venmo%' and e.description not like '%gmail%'
     and position(chr(8212) in e.description) = 0;
  if n <> 1 then raise exception 'locker decorating event not as intended (found %)', n; end if;

  select count(*) into n from events where starts_at::date = date '2026-10-08';
  if n <> 1 then raise exception 'expected exactly 1 event on Oct 8, found %', n; end if;
end $$;

commit;
