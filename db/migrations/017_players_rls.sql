-- Migration 017: RLS policies for players

ALTER TABLE players ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone reads players on active rosters" ON players
  FOR SELECT TO anon
  USING (
    active = true
    AND EXISTS (
      SELECT 1 FROM rosters
      WHERE rosters.id = players.roster_id
      AND rosters.active = true
    )
  );

CREATE POLICY "Authenticated read all players" ON players
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));

CREATE POLICY "Content admins write players" ON players
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins update players" ON players
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins delete players" ON players
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));
