-- Migration 002: Auth and roles (user_roles table + current_user_has_role helper)

CREATE TABLE user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);

CREATE OR REPLACE FUNCTION current_user_has_role(required_role user_role)
RETURNS boolean
LANGUAGE sql STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
    AND (role = required_role OR role = 'super_admin')
  );
$$;

-- SECURITY DEFINER lets this function read user_roles regardless of caller RLS,
-- which is the standard Supabase pattern for role-check helpers.
-- search_path is pinned to prevent search-path injection.
REVOKE EXECUTE ON FUNCTION current_user_has_role(user_role) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION current_user_has_role(user_role) TO authenticated;
-- Not granted to anon: anon never has a uid() so the function would always return false.
-- RLS policies that reference this function execute as the database, not the caller,
-- so anon-targeted policies still work without anon needing EXECUTE.
