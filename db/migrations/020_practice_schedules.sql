-- Migration 020: practice_schedules table (shared across freshman Green/Blue — no team_designation)

CREATE TABLE practice_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year text NOT NULL,
  team_level team_level NOT NULL,
  body text NOT NULL DEFAULT '',
  source_note text,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (year, team_level)
);

CREATE INDEX idx_practice_schedules_year_active ON practice_schedules(year, active);

CREATE TRIGGER touch_practice_schedules BEFORE UPDATE ON practice_schedules
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
