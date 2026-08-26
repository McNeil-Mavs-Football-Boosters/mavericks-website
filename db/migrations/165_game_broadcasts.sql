-- 165_game_broadcasts.sql
--
-- Broadcast links on the schedule. VYPE is streaming McNeil varsity this
-- season; Merle Bertrand (VYPE) mailed president@ / the boosters gmail / Coach
-- Gardner on 2026-08-24 with the arrangement and week 4's two links.
--
-- ── WHY A CHILD TABLE AND NOT A SECOND COLUMN ──
-- There are TWO links per game, not one: the VYPE watch page and the YouTube
-- live URL it embeds. A `vype_url` column beside `watch_url` would bake one
-- vendor into the schema and still not survive the actual cadence, which
-- Merle stated plainly: "I'll try to send out the direct links each week but
-- I'm making no promises in case I can't keep up." So across the season we get
-- games with two links, games with one, and games with NONE (where the only
-- answer is VYPE's "Broadcast Lineup" article, posted each game day). One row
-- per link handles 0..N with no further schema churn, and it carries the LABEL
-- as data so "VYPE" vs "YouTube" is not hardcoded in a component.
--
-- ── `keep_after_final` EXISTS BECAUSE THE TWO LINKS AGE DIFFERENTLY ──
-- A YouTube live URL normally survives the broadcast as a replay, and a parent
-- who missed the game is exactly the person who wants it on Saturday. A
-- per-game VYPE page is far more likely to rot. Rather than guess in code, each
-- row says whether it outlives the final whistle. Jeremy 2026-08-26: keep it up
-- after.
--
-- ⚠️ `games.watch_url` IS EMPTIED BUT NOT DROPPED, AND THAT IS DELIBERATE.
-- 161, 162, 163 and 164 all shipped into this same code in the last two days.
-- Dropping a column in the same change is how a surprise happens. **Phase 2 (a
-- later migration) drops the dead column.** Do not add new writers to it.
--
-- ⚠️ IT WAS NOT NULL EVERYWHERE — THERE IS EXACTLY ONE LEGACY ROW, AND MISSING
-- IT WOULD HAVE SILENTLY DROPPED A LINK. All 48 rows of 2026-27 are null, which
-- is what a year-scoped check shows and what this migration first assumed. But
-- migration 052 set `watch_url = 'https://www.youtube.com/@iHSFan'` on the
-- **2025-26** Hutto game (2025-11-07), the backfilled season's last game, which
-- was deliberately left at `result_status = 'scheduled'` so the Result cell
-- would render "Watch →" instead of an em-dash. `site_settings
-- .current_schedule_year` is 2026-27, so that row is invisible on the site
-- today — but its renderer is the very branch this commit removes, so it is
-- carried into `game_broadcasts` below rather than stranded. After this there
-- is exactly ONE place a broadcast link comes from.
--
-- ── THE DEDICATED "WATCH" COLUMN IS NOT COMING BACK ──
-- It was spec'd (`commit_b_spec.md`), built, and REMOVED by Jeremy's own review
-- on 2026-05-26 (commit b4590af) because it was empty on all 11 rows and read
-- as dead weight. VYPE broadcasts VARSITY ONLY, so a dedicated column would be
-- empty on every JV and freshman page and on most varsity rows too — the exact
-- same dead weight. These links render in the existing right-hand action column
-- alongside "Tickets →", whose header becomes "Links".
--
-- `content_map_v2.md` line 156 left this open: "final games with `watch_url`
-- are an open question (do we want to surface a post-game replay link
-- separately?). Defer until a real use case arises." The use case arrived.
--
-- DB-ONLY FOR THE DATA, BUT THIS ONE DOES NEED A DEPLOY — unlike 164, the
-- render change is in code.

begin;

create table if not exists game_broadcasts (
  id               uuid primary key default gen_random_uuid(),
  game_id          uuid not null references games(id) on delete cascade,
  label            text not null,
  url              text not null,
  sort_order       int  not null default 0,
  keep_after_final boolean not null default false,
  active           boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint game_broadcasts_label_not_blank check (btrim(label) <> ''),
  constraint game_broadcasts_url_is_http check (url ~ '^https?://'),
  -- The same destination twice on one game is always a mistake.
  constraint game_broadcasts_unique_url unique (game_id, url)
);

comment on table game_broadcasts is
  'Broadcast / stream links for a game. Zero or more rows per game; VYPE '
  'typically gives two (their watch page plus the YouTube live URL it embeds). '
  'Renders in the schedule''s right-hand action column next to Tickets. '
  'Supersedes games.watch_url, which is inert as of migration 165.';

comment on column game_broadcasts.label is
  'Short link text, rendered as "<label> →". Keep it to one word where possible '
  'so the action column does not widen: "VYPE", "YouTube", "Replay".';

comment on column game_broadcasts.keep_after_final is
  'Whether this link stays visible once the game is final. True for a YouTube '
  'live URL, which persists as a replay. False for a per-game vendor page that '
  'is likely to rot. Nothing here auto-expires a link; false simply hides it '
  'once result_status = final.';

comment on column game_broadcasts.sort_order is
  'Display order within one game, ascending. Ties fall back to label.';

create index if not exists game_broadcasts_game_id_idx
  on game_broadcasts (game_id);

create trigger touch_game_broadcasts
  before update on game_broadcasts
  for each row execute function touch_updated_at();

grant select on game_broadcasts to anon, authenticated;
grant insert, update, delete on game_broadcasts to authenticated;

alter table game_broadcasts enable row level security;

create policy "Anyone reads game_broadcasts" on game_broadcasts
  for select to anon using (true);
create policy "Authenticated read game_broadcasts" on game_broadcasts
  for select to authenticated using (true);
create policy "Content admins write game_broadcasts" on game_broadcasts
  for insert to authenticated with check (current_user_has_role('content_admin'));
create policy "Content admins update game_broadcasts" on game_broadcasts
  for update to authenticated using (current_user_has_role('content_admin'))
  with check (current_user_has_role('content_admin'));
create policy "Content admins delete game_broadcasts" on game_broadcasts
  for delete to authenticated using (current_user_has_role('content_admin'));

-- ── Week 4: varsity at Bowie, Fri Aug 28, 7:30 p.m. ─────────────────────────
-- Both links verified 200 on 2026-08-26 and titled for this game: the VYPE page
-- reads "7:30PM - Football: Bowie vs. McNeil", the YouTube page "7:30PM -
-- Football: McNeil vs. Bowie".
--
-- The game is selected by its ACTUAL IDENTITY (year + level + date + opponent),
-- not by a pasted uuid, so this fails loudly if the row it expects moved.
insert into game_broadcasts (game_id, label, url, sort_order, keep_after_final)
select g.id, v.label, v.url, v.sort_order, v.keep_after_final
from games g
cross join (values
    -- YouTube first: it is the thing that actually plays, and it is the one
    -- that survives as a replay.
    ('YouTube', 'https://youtube.com/live/1Mhca5ZNT6o', 1, true),
    -- The VYPE page carries their pre-roll ads and their own chrome. Kept
    -- because Merle asked for it and because it is where a corrected link
    -- would appear if the YouTube id changes; dropped once the game is final.
    ('VYPE', 'https://www.vype.com/7-30pm-football-bowie-vs-mcneil', 2, false)
  ) as v(label, url, sort_order, keep_after_final)
where g.year = '2026-27'
  and g.team_level = 'varsity'
  and g.team_designation is null
  and g.game_date >= timestamptz '2026-08-28 00:00 America/Chicago'
  and g.game_date <  timestamptz '2026-08-29 00:00 America/Chicago'
  and g.opponent = 'Austin Bowie High School'
on conflict (game_id, url) do nothing;

-- ── Carry the one legacy `games.watch_url` across, then blank it ────────────
-- The 2025-26 Hutto row (migration 052). Generic — it moves whatever it finds
-- rather than hardcoding that one game, so it stays correct if another turns up.
-- Labelled "Watch" because the destination is the iHSFan CHANNEL, not a
-- specific broadcast, so "YouTube" would overpromise. keep_after_final is true:
-- a channel URL does not rot, and the game is long over.
insert into game_broadcasts (game_id, label, url, sort_order, keep_after_final)
select g.id, 'Watch', g.watch_url, 1, true
from games g
where g.watch_url is not null
on conflict (game_id, url) do nothing;

update games set watch_url = null where watch_url is not null;

do $$
declare n int; gid uuid;
begin
  select g.id into gid from games g
   where g.year = '2026-27' and g.team_level = 'varsity'
     and g.team_designation is null
     and g.game_date >= timestamptz '2026-08-28 00:00 America/Chicago'
     and g.game_date <  timestamptz '2026-08-29 00:00 America/Chicago'
     and g.opponent = 'Austin Bowie High School';
  if gid is null then
    raise exception 'the Fri Aug 28 varsity game vs Austin Bowie was not found';
  end if;

  select count(*) into n from game_broadcasts where game_id = gid and active;
  if n <> 2 then
    raise exception 'expected 2 broadcast links on the Aug 28 varsity game, found %', n;
  end if;

  -- The YouTube link is the one that must outlive the game.
  select count(*) into n from game_broadcasts
   where game_id = gid and label = 'YouTube' and keep_after_final;
  if n <> 1 then
    raise exception 'the YouTube link is not marked keep_after_final';
  end if;

  -- Exactly two games carry links: this one, and the 2025-26 Hutto row carried
  -- over from watch_url. A third would mean a stray insert put a Bowie stream
  -- on somebody else's schedule.
  select count(distinct game_id) into n from game_broadcasts;
  if n <> 2 then
    raise exception 'expected links on exactly 2 games, found %', n;
  end if;

  -- The legacy row made it across before the column was blanked. If this fails,
  -- a link was silently dropped rather than migrated.
  select count(*) into n from game_broadcasts b
   join games g on g.id = b.game_id
   where g.year = '2025-26' and b.url = 'https://www.youtube.com/@iHSFan';
  if n <> 1 then
    raise exception 'the legacy 2025-26 watch_url was not carried over (found %)', n;
  end if;

  -- Nothing reads games.watch_url after this commit, so nothing may still be
  -- sitting in it. Phase 2 drops the column.
  select count(*) into n from games where watch_url is not null;
  if n <> 0 then
    raise exception '% games still have a watch_url after the carry-over', n;
  end if;
end $$;

commit;
