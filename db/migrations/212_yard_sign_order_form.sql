-- 212_yard_sign_order_form.sql
--
-- 2026 Player Yard Sign Order Form ($30) on /resources under Registration &
-- Forms, right after the Game-Day Meal Program. Jeremy 2026-09-22: "we need to
-- be promoting this on the website and on the newsletter ... (not the edit
-- version)". URL is the /viewform form of the id he gave; Google redirects it
-- to the public /d/e/... respondent link, so a parent never sees the editor.
--
-- What the live form says (read headless 9/22): "$30. All orders will be
-- delivered to school and may be picked up at a home game, or you can indicate
-- that you would like us to give them to your athlete." The description here
-- restates only that.
--
-- ⚠️ THE FORM'S OWN HEADER STILL SAYS "Order deadline is Friday, September 8,
-- 2026." That date has passed (and Sep 8 2026 is a Tuesday). The 9/22 minutes
-- have Ashley placing the combined senior + yard sign order with Super Cheap
-- Signs Thu/Fri Sep 24-25, so ordering is live. NO DEADLINE IS STATED HERE: the
-- site does not publish a date nobody has set (standing rule). The form header
-- needs fixing in the booster account; flagged to Jeremy.
--
-- DB-ONLY, NO DEPLOY. Rollback: 212_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from resource_links where url like '%1zFsehMoFYR4SS6Ow17CML9HZuds34bEgR8q0Z4iFm5s%';
  if n <> 0 then raise exception 'yard sign form already linked'; end if;
end $$;

insert into resource_links (section, label, url, description, icon_hint, sort_order, active)
values ('registration_forms',
        '2026 Player Yard Sign ($30)',
        'https://docs.google.com/forms/d/1zFsehMoFYR4SS6Ow17CML9HZuds34bEgR8q0Z4iFm5s/viewform',
        'Order your athlete''s 2026 yard sign. Signs are delivered to the school: pick yours up at a home game, or ask for it to go home with your athlete.',
        'form', 5, true);

do $$
declare n int;
begin
  select count(*) into n from resource_links
   where section = 'registration_forms' and active and url like '%1zFsehMoFYR4SS6Ow17CML9HZuds34bEgR8q0Z4iFm5s/viewform'
     and url not like '%/edit%';
  if n <> 1 then raise exception 'yard sign link not as intended'; end if;
end $$;

commit;
