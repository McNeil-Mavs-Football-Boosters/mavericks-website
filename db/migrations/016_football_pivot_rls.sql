-- Migration 016: RLS policies for games, rosters, coaches, resource_links

-- games
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads games" ON games
  FOR SELECT TO anon
  USING (true);
CREATE POLICY "Authenticated read all games" ON games
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write games" ON games
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update games" ON games
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete games" ON games
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- rosters: anon reads only active rows; admins see archive too
ALTER TABLE rosters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active rosters" ON rosters
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all rosters" ON rosters
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write rosters" ON rosters
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update rosters" ON rosters
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete rosters" ON rosters
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- coaches: anon reads only active rows
ALTER TABLE coaches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active coaches" ON coaches
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all coaches" ON coaches
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write coaches" ON coaches
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update coaches" ON coaches
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete coaches" ON coaches
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- resource_links: anon reads only active rows
ALTER TABLE resource_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active resource links" ON resource_links
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all resource links" ON resource_links
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write resource links" ON resource_links
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update resource links" ON resource_links
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete resource links" ON resource_links
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));
