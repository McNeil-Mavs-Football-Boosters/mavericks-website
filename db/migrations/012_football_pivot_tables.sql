-- Migration 012: Football pivot tables (games, rosters, coaches, resource_links)

CREATE TABLE games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year text NOT NULL,                          -- "2026-27"
  team_level team_level NOT NULL,
  opponent text NOT NULL,                      -- "Round Rock"
  opponent_url text,                           -- optional, link to opponent's site
  game_date timestamptz NOT NULL,              -- kickoff time
  location text,                               -- "Kelly Reeves Athletic Complex"
  location_url text,                           -- optional, e.g., Google Maps link
  home_or_away home_or_away NOT NULL DEFAULT 'home',
  our_score integer CHECK (our_score IS NULL OR our_score >= 0),
  their_score integer CHECK (their_score IS NULL OR their_score >= 0),
  result_status game_result_status NOT NULL DEFAULT 'scheduled',
  watch_url text,                              -- YouTube, TexanLive, etc.
  maxpreps_game_url text,                      -- per-game deep link (optional)
  notes text,                                  -- "Homecoming", "Senior Night", etc.
  featured boolean NOT NULL DEFAULT false,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_games_year_team_date ON games(year, team_level, game_date);
CREATE INDEX idx_games_year_date ON games(year, game_date);
CREATE INDEX idx_games_status_date ON games(result_status, game_date);
CREATE INDEX idx_games_featured ON games(featured) WHERE featured = true;

CREATE TABLE rosters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year text NOT NULL,                          -- "2026-27"
  team_level team_level NOT NULL,
  body text NOT NULL DEFAULT '',               -- markdown
  source_note text,                            -- "Provided by Coach [Name] on YYYY-MM-DD"
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (year, team_level)
);

CREATE INDEX idx_rosters_year_active ON rosters(year, active);

CREATE TABLE coaches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year text NOT NULL,                          -- "2026-27"
  name text NOT NULL,
  role text NOT NULL,                          -- "Defensive Coordinator"
  role_category coach_role_category NOT NULL,
  phone text,
  email text,
  photo_url text,
  bio text,                                    -- markdown
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_coaches_year_active_sort ON coaches(year, active, sort_order);
CREATE INDEX idx_coaches_year_category_sort ON coaches(year, role_category, sort_order);

CREATE TABLE resource_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section resource_section NOT NULL,
  label text NOT NULL,                         -- "Aktivate Registration"
  url text NOT NULL,                           -- external URL or internal path
  description text,                            -- one-line context shown below the link
  icon_hint text,                              -- "external", "pdf", "form", "video"
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_resource_links_section_active_sort
  ON resource_links(section, active, sort_order);
