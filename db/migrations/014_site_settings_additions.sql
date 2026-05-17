-- Migration 014: site_settings additions for football-first home page and footer

ALTER TABLE site_settings
  ADD COLUMN maxpreps_team_url text DEFAULT 'https://www.maxpreps.com/tx/austin/mcneil-mavericks/football/',
  ADD COLUMN season_label text,
  ADD COLUMN season_opener_date timestamptz,
  ADD COLUMN next_game_override text,
  ADD COLUMN current_year text NOT NULL DEFAULT '2026-27';
