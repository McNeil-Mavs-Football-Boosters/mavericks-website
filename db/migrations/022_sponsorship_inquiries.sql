-- Migration 022: sponsorship_inquiries (type + table + indexes + trigger + RLS).
-- Anon writes go through a server-side /api/sponsorship/create route using the
-- service-role key (same pattern as memberships and /api/contact). No anon access here.

CREATE TYPE sponsorship_inquiry_status AS ENUM ('new', 'in_progress', 'closed_won', 'closed_lost');

CREATE TABLE sponsorship_inquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name text NOT NULL,
  contact_name text NOT NULL,
  contact_email text NOT NULL,
  contact_phone text,
  tier_id uuid REFERENCES sponsorship_tiers(id) ON DELETE SET NULL,
  message text,
  logo_url text,
  status sponsorship_inquiry_status NOT NULL DEFAULT 'new',
  notes text,
  year text NOT NULL,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_sponsorship_inquiries_status_created ON sponsorship_inquiries(status, created_at DESC);
CREATE INDEX idx_sponsorship_inquiries_year ON sponsorship_inquiries(year);

CREATE TRIGGER touch_sponsorship_inquiries BEFORE UPDATE ON sponsorship_inquiries
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

ALTER TABLE sponsorship_inquiries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Content admins read sponsorship inquiries" ON sponsorship_inquiries
  FOR SELECT TO authenticated
  USING (current_user_has_role('content_admin'));

CREATE POLICY "Content admins write sponsorship inquiries" ON sponsorship_inquiries
  FOR INSERT TO authenticated
  WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins update sponsorship inquiries" ON sponsorship_inquiries
  FOR UPDATE TO authenticated
  USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins delete sponsorship inquiries" ON sponsorship_inquiries
  FOR DELETE TO authenticated
  USING (current_user_has_role('content_admin'));
