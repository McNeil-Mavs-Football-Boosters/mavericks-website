-- Migration 013: Players table (structured player records per roster)

CREATE TABLE players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  roster_id uuid NOT NULL REFERENCES rosters(id) ON DELETE CASCADE,
  jersey_number text,                          -- text, not int (some teams use 00, letters)
  first_name text NOT NULL,
  last_name text NOT NULL,
  position text,                               -- "QB", "WR", "OL/DL", or null
  grade text,                                  -- "Sr.", "Jr.", "So.", "Fr.", or null
  height text,                                 -- "6'2"", or null
  weight integer CHECK (weight IS NULL OR weight > 0),
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_players_roster ON players(roster_id);
CREATE INDEX idx_players_roster_sort ON players(roster_id, sort_order);
CREATE INDEX idx_players_roster_active_sort ON players(roster_id, active, sort_order)
  WHERE active = true;

CREATE TRIGGER touch_players BEFORE UPDATE ON players
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
