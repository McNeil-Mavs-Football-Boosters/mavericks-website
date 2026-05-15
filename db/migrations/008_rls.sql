-- Migration 008: Row-Level Security (RLS)

-- Default: RLS enabled on every table. No policies = no access (deny by default).
-- Then add policies explicitly.

-- =============================================================================
-- Public content tables — full policy set
-- =============================================================================
-- Every table here gets the same pattern: anon SELECT for "visible" rows,
-- content_admin gets full CRUD.

-- news_posts: anon sees published; admins see/edit everything
ALTER TABLE news_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads published news" ON news_posts
  FOR SELECT TO anon
  USING (status = 'published');
CREATE POLICY "Authenticated read all news" ON news_posts
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write news" ON news_posts
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update news" ON news_posts
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete news" ON news_posts
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- events: anon sees published + cancelled (so bookmarked URLs still work)
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads visible events" ON events
  FOR SELECT TO anon
  USING (status IN ('published', 'cancelled'));
CREATE POLICY "Authenticated read all events" ON events
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write events" ON events
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update events" ON events
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete events" ON events
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- membership_tiers
ALTER TABLE membership_tiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active membership tiers" ON membership_tiers
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all membership tiers" ON membership_tiers
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write membership tiers" ON membership_tiers
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update membership tiers" ON membership_tiers
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete membership tiers" ON membership_tiers
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- sponsorship_tiers
ALTER TABLE sponsorship_tiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active sponsorship tiers" ON sponsorship_tiers
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all sponsorship tiers" ON sponsorship_tiers
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write sponsorship tiers" ON sponsorship_tiers
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update sponsorship tiers" ON sponsorship_tiers
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete sponsorship tiers" ON sponsorship_tiers
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- sponsors
ALTER TABLE sponsors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active sponsors" ON sponsors
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all sponsors" ON sponsors
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write sponsors" ON sponsors
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update sponsors" ON sponsors
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete sponsors" ON sponsors
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- board_members
ALTER TABLE board_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active board members" ON board_members
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all board members" ON board_members
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write board members" ON board_members
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update board members" ON board_members
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete board members" ON board_members
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- committees
ALTER TABLE committees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active committees" ON committees
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all committees" ON committees
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write committees" ON committees
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update committees" ON committees
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete committees" ON committees
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- volunteer_opportunities
ALTER TABLE volunteer_opportunities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active volunteer opportunities" ON volunteer_opportunities
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all volunteer opportunities" ON volunteer_opportunities
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write volunteer opportunities" ON volunteer_opportunities
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update volunteer opportunities" ON volunteer_opportunities
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete volunteer opportunities" ON volunteer_opportunities
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- documents (no public column in Phase 1; visibility gated by active only)
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads active documents" ON documents
  FOR SELECT TO anon
  USING (active = true);
CREATE POLICY "Authenticated read all documents" ON documents
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write documents" ON documents
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update documents" ON documents
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete documents" ON documents
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- site_settings (singleton)
ALTER TABLE site_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone reads site settings" ON site_settings
  FOR SELECT TO anon, authenticated
  USING (true);
CREATE POLICY "Content admins update site settings" ON site_settings
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
-- No INSERT/DELETE policies — singleton row created at schema setup, never added or removed.

-- =============================================================================
-- Private tables — memberships and payments
-- =============================================================================
-- memberships rows are never directly readable by anonymous visitors.
-- The /members page reads from the public_members view (defined in 007_views.sql)
-- which exposes only display-safe columns.

-- memberships table RLS — no anon access at all
ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;

-- No anon SELECT, INSERT, UPDATE, or DELETE.
-- Anon reads only the public_members view (which exposes safe columns).
-- Anon writes only via the server-side /api/memberships/create endpoint (service role key).

-- Content admins manage everything
CREATE POLICY "Content admins read memberships" ON memberships
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));
CREATE POLICY "Content admins write memberships" ON memberships
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins update memberships" ON memberships
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));
CREATE POLICY "Content admins delete memberships" ON memberships
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));

-- Readonly admins (treasurer) can read but not write
CREATE POLICY "Readonly admins read memberships" ON memberships
  FOR SELECT TO authenticated
  USING (current_user_has_role('readonly_admin'));

-- Payments RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- No anon access at all
CREATE POLICY "Super and readonly admins read payments" ON payments
  FOR SELECT TO authenticated
  USING (current_user_has_role('super_admin') OR current_user_has_role('readonly_admin'));
CREATE POLICY "Super admins write payments" ON payments
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('super_admin'));
CREATE POLICY "Super admins update payments" ON payments
  FOR UPDATE TO authenticated
  USING (current_user_has_role('super_admin'))
  WITH CHECK (current_user_has_role('super_admin'));
-- NO DELETE policy on payments. Payment records are financial history.
-- Refunds use status = 'refunded'. Corrections use the notes field.
-- A real delete (e.g., test data cleanup) requires the service role key
-- and direct SQL — forced friction to protect Treasurer trust and reconciliation
-- against Stripe's immutable record.
--
-- Stripe webhook writes via the service role key (bypasses RLS), not via these policies.

-- =============================================================================
-- user_roles RLS
-- =============================================================================

ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read their own roles" ON user_roles
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());
CREATE POLICY "Super admins read all roles" ON user_roles
  FOR SELECT TO authenticated
  USING (current_user_has_role('super_admin'));
CREATE POLICY "Super admins write roles" ON user_roles
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('super_admin'));
CREATE POLICY "Super admins update roles" ON user_roles
  FOR UPDATE TO authenticated
  USING (current_user_has_role('super_admin'))
  WITH CHECK (current_user_has_role('super_admin'));
CREATE POLICY "Super admins delete roles" ON user_roles
  FOR DELETE TO authenticated
  USING (current_user_has_role('super_admin'));
