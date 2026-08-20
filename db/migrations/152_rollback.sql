-- 152_rollback.sql — removes the scrimmage no-meals warning from all three
-- practice bodies. Deletes the bullet including its leading newline, so no
-- blank line is left inside the Thursday block.

begin;

update practice_schedules
set body = replace(
  body,
  E'\n- **Bring extra food or a snack.** Meals are not provided for scrimmages.',
  ''
)
where year = '2026-27'
  and body like '%Meals are not provided for scrimmages%';

do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Meals are not provided for scrimmages%';
  if n <> 0 then
    raise exception '% bodies still carry the warning', n;
  end if;
end $$;

commit;
