
-- ===
-- db/migrations/001_extensions_and_types.sql
-- ===

-- Migration 001: Extensions and enum types

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role AS ENUM ('super_admin', 'content_admin', 'readonly_admin');

CREATE TYPE post_status AS ENUM ('draft', 'published');

CREATE TYPE event_status AS ENUM ('draft', 'published', 'cancelled');

CREATE TYPE committee_cadence AS ENUM ('ongoing', 'seasonal', 'one_time');

CREATE TYPE document_type AS ENUM ('governance', 'financial', 'minutes', 'sponsor_flyer', 'other');

CREATE TYPE payment_method_type AS ENUM ('stripe', 'cash', 'check', 'zero_dollar', 'other');
CREATE TYPE payment_purpose AS ENUM ('membership', 'donation', 'sponsorship');
CREATE TYPE payment_status AS ENUM ('pending', 'succeeded', 'failed', 'canceled', 'refunded');

-- ===
-- db/migrations/002_auth_and_roles.sql
-- ===

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

-- ===
-- db/migrations/003_content_tables.sql
-- ===

-- Migration 003: Content tables (news, events, tiers, sponsors, board, committees, volunteer, documents)

-- news_posts
CREATE TABLE news_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  excerpt text,
  body text NOT NULL,
  featured_image_url text,
  author text,
  status post_status NOT NULL DEFAULT 'draft',
  published_at timestamptz,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_news_posts_status_published_at ON news_posts(status, published_at DESC);
CREATE INDEX idx_news_posts_slug ON news_posts(slug);

-- events
CREATE TABLE events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  description text,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz,
  location text,
  location_url text,
  signup_url text,
  cover_image_url text,
  status event_status NOT NULL DEFAULT 'draft',
  featured boolean NOT NULL DEFAULT false,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_events_status_starts_at ON events(status, starts_at);
CREATE INDEX idx_events_featured ON events(featured) WHERE featured = true;
CREATE INDEX idx_events_slug ON events(slug);

-- membership_tiers
CREATE TABLE membership_tiers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  price_cents integer NOT NULL CHECK (price_cents >= 0),
  description text,
  perks jsonb NOT NULL DEFAULT '[]'::jsonb,  -- array of strings
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  year text NOT NULL,  -- "2026-27"
  requires_tshirt_size boolean NOT NULL DEFAULT false,
  requires_second_tshirt_size boolean NOT NULL DEFAULT false,
  badge_label text,  -- nullable, e.g., "Most Popular"
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_membership_tiers_year_active_sort ON membership_tiers(year, active, sort_order);

-- sponsorship_tiers
CREATE TABLE sponsorship_tiers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  price_cents integer NOT NULL CHECK (price_cents >= 0),
  description text,
  perks jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  year text NOT NULL,
  badge_label text,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_sponsorship_tiers_year_active_sort ON sponsorship_tiers(year, active, sort_order);

-- sponsors
CREATE TABLE sponsors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  logo_url text,
  website_url text,
  tier_id uuid REFERENCES sponsorship_tiers(id) ON DELETE SET NULL,
  -- payment_id FK added later via ALTER TABLE, after the payments table is defined
  year text NOT NULL,
  featured boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_sponsors_year_active ON sponsors(year, active);
CREATE INDEX idx_sponsors_tier_id ON sponsors(tier_id);

-- board_members
CREATE TABLE board_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  role text NOT NULL,
  email_alias text,  -- e.g., "president@mcneilmavericks.org"; displayed only if populated AND aliases are live
  bio text,
  photo_url text,
  sort_order integer NOT NULL DEFAULT 0,
  year text NOT NULL,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_board_members_year_active_sort ON board_members(year, active, sort_order);

-- committees
CREATE TABLE committees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL,
  cadence committee_cadence NOT NULL,
  chair_board_member_id uuid REFERENCES board_members(id) ON DELETE SET NULL,
  contact_email text,
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_committees_active_sort ON committees(active, sort_order);

-- volunteer_opportunities
CREATE TABLE volunteer_opportunities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  when_text text,  -- "Friday nights, fall season"
  what_you_do text,
  what_you_get text,
  signup_url text,  -- external SignUpGenius link, or internal route Phase 2
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_volunteer_opportunities_active_sort ON volunteer_opportunities(active, sort_order);

-- documents
CREATE TABLE documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  file_url text NOT NULL,
  doc_type document_type NOT NULL,
  doc_date date,
  -- NOTE: no `public` column in Phase 1. All documents go in the public Storage bucket
  -- and are visible to anyone. A `public` toggle would be misleading because the file
  -- itself loads from a public bucket regardless of the DB flag. If/when Phase 2 adds a
  -- private bucket for confidential financials, restore the column and gate the storage
  -- bucket selection on it.
  active boolean NOT NULL DEFAULT true,  -- soft-archive (admin_scope says "archive don't delete")
  sort_order integer NOT NULL DEFAULT 0,
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_documents_type_date ON documents(doc_type, doc_date DESC) WHERE active = true;

-- ===
-- db/migrations/004_transactional_tables.sql
-- ===

-- Migration 004: Transactional tables (payments, memberships) + sponsors.payment_id FK

CREATE TABLE payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_session_id text UNIQUE,  -- null for non-Stripe payments
  stripe_payment_intent_id text UNIQUE,
  method payment_method_type NOT NULL,
  purpose payment_purpose NOT NULL,
  amount_cents integer NOT NULL CHECK (amount_cents >= 0),
  status payment_status NOT NULL DEFAULT 'pending',
  payer_email text,
  payer_name text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,  -- arbitrary form data, useful for donations not tied to membership
  notes text,  -- admin-entered notes, e.g., "check #1234 received 2026-05-15"
  recorded_by uuid REFERENCES auth.users(id),  -- null for self-service Stripe; populated for manual entries
  last_edited_by uuid REFERENCES auth.users(id),  -- updated whenever an admin edits notes/status
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_payments_status_created_at ON payments(status, created_at DESC);
CREATE INDEX idx_payments_purpose ON payments(purpose);
CREATE INDEX idx_payments_payer_email ON payments(payer_email);

-- Now that payments exists, wire up the sponsors → payments FK (deferred from earlier table creation)
ALTER TABLE sponsors
  ADD COLUMN payment_id uuid REFERENCES payments(id) ON DELETE SET NULL;
COMMENT ON COLUMN sponsors.payment_id IS 'Links the sponsor''s inbound Stripe payment to the sponsor record for Treasurer reconciliation. Nullable for manual or legacy entries.';

CREATE INDEX idx_sponsors_payment_id ON sponsors(payment_id);

CREATE TABLE memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year text NOT NULL,  -- "2026-27"
  tier_id uuid NOT NULL REFERENCES membership_tiers(id) ON DELETE RESTRICT,

  parent_1_name text NOT NULL,
  parent_1_email text NOT NULL,
  parent_1_phone text,
  parent_2_name text,
  parent_2_email text,
  parent_2_phone text,

  players text,  -- "Player Name(s) and Grade(s)" free text from existing form

  tshirt_size_1 text,
  tshirt_size_2 text,

  additional_donation_cents integer NOT NULL DEFAULT 0 CHECK (additional_donation_cents >= 0),
  employer_match_name text,

  sportsyou_optin boolean NOT NULL DEFAULT false,
  list_publicly boolean NOT NULL DEFAULT false,

  paid boolean NOT NULL DEFAULT false,
  payment_id uuid REFERENCES payments(id) ON DELETE SET NULL,

  active boolean NOT NULL DEFAULT true,  -- soft-delete for duplicates, test data, or spam only. NOT used for year rollover — that's handled by filtering on `year`. Admin UI default list filter is `year = current_year`, with no `active` filter (admins see soft-deleted rows like a trash can so they can un-delete).
  last_edited_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_memberships_year_tier ON memberships(year, tier_id);
CREATE INDEX idx_memberships_year_paid_active ON memberships(year, paid, active);
CREATE INDEX idx_memberships_parent_1_email ON memberships(parent_1_email);
CREATE INDEX idx_memberships_year_list_publicly ON memberships(year, list_publicly) WHERE list_publicly = true;

-- ===
-- db/migrations/005_settings.sql
-- ===

-- Migration 005: Settings tables (site_settings singleton)

CREATE TABLE site_settings (
  id integer PRIMARY KEY DEFAULT 1,
  -- Organization
  legal_name text NOT NULL DEFAULT 'McNeil Maverick Football Booster Club',
  display_name text NOT NULL DEFAULT 'McNeil Mavericks Football Booster Club',
  ein text NOT NULL DEFAULT '26-4231242',
  mailing_address text,
  primary_contact_email text NOT NULL DEFAULT 'boosters@mcneilmavericks.org',
  school_affiliation_disclaimer text NOT NULL DEFAULT 'This website is maintained by the McNeil Maverick Football Booster Club and is not a part of McNeil High School or Round Rock ISD. Neither McNeil High School nor Round Rock ISD is responsible for the content or opinions within this website.',

  -- Social
  facebook_group_url text,
  instagram_url text,
  youtube_url text,

  -- Homepage
  hero_image_url text,
  hero_headline text NOT NULL DEFAULT 'McNeil Mavericks Football Booster Club',
  hero_subhead text,
  primary_cta_label text NOT NULL DEFAULT 'Join the Club',
  primary_cta_url text NOT NULL DEFAULT '/join',
  quick_action_card_1 text NOT NULL DEFAULT 'join',
  quick_action_card_2 text NOT NULL DEFAULT 'sponsor',
  quick_action_card_3 text NOT NULL DEFAULT 'donate',

  -- Email aliases (display only)
  alias_boosters text,
  alias_president text,
  alias_treasurer text,
  alias_secretary text,
  alias_webmaster text,
  alias_sponsorship text,

  last_edited_by uuid REFERENCES auth.users(id),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (id = 1)  -- enforce singleton
);

INSERT INTO site_settings (id) VALUES (1) ON CONFLICT DO NOTHING;

-- ===
-- db/migrations/006_triggers.sql
-- ===

-- Migration 006: Trigger functions and triggers (touch_updated_at, validate_membership_paid_state)

CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Integrity: paid=true requires either a payment row OR the tier's price is $0
-- Implemented as a trigger so it stays correct even if a tier's price changes
-- or a membership's tier_id is updated.
CREATE OR REPLACE FUNCTION validate_membership_paid_state()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  tier_price_cents integer;
BEGIN
  IF NEW.paid = false THEN
    RETURN NEW;  -- unpaid rows are always valid
  END IF;

  -- paid = true; check the exemption rules
  IF NEW.payment_id IS NOT NULL THEN
    RETURN NEW;  -- linked to a payment row
  END IF;

  -- No payment_id; allowed only if the tier is $0
  SELECT price_cents INTO tier_price_cents FROM membership_tiers WHERE id = NEW.tier_id;
  IF tier_price_cents = 0 THEN
    RETURN NEW;  -- $0 tier exemption
  END IF;

  RAISE EXCEPTION 'paid=true requires either a payment_id or a $0-priced tier (tier_id=%, price_cents=%)', NEW.tier_id, tier_price_cents;
END;
$$;

-- Apply to every table with updated_at
CREATE TRIGGER touch_news_posts BEFORE UPDATE ON news_posts FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_events BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_membership_tiers BEFORE UPDATE ON membership_tiers FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_sponsorship_tiers BEFORE UPDATE ON sponsorship_tiers FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_sponsors BEFORE UPDATE ON sponsors FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_board_members BEFORE UPDATE ON board_members FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_committees BEFORE UPDATE ON committees FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_volunteer_opportunities BEFORE UPDATE ON volunteer_opportunities FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_documents BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_memberships BEFORE UPDATE ON memberships FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_payments BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_site_settings BEFORE UPDATE ON site_settings FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TRIGGER validate_membership_paid_state_trigger
  BEFORE INSERT OR UPDATE ON memberships
  FOR EACH ROW
  EXECUTE FUNCTION validate_membership_paid_state();

-- ===
-- db/migrations/007_views.sql
-- ===

-- Migration 007: Views (public_members)

-- View exposes only display-safe columns: id, year, tier name + sort, parent names.
-- Does NOT expose: emails, phones, t-shirt sizes, donation amounts, employer match,
-- SportsYou opt-in status, paid status, payment_id.
--
-- security_invoker = false means the view runs as its owner (the postgres superuser
-- in Supabase), bypassing the underlying memberships table RLS. That's the entire
-- point of using a view here — column-level safety the RLS row-filter can't provide.

CREATE VIEW public_members
WITH (security_invoker = false)
AS
  SELECT
    m.id,
    m.year,
    mt.name AS tier_name,
    mt.sort_order AS tier_sort_order,
    m.parent_1_name,
    m.parent_2_name
  FROM memberships m
  JOIN membership_tiers mt ON mt.id = m.tier_id
  WHERE m.list_publicly = true
    AND m.paid = true
    AND m.active = true
    AND mt.active = true;

GRANT SELECT ON public_members TO anon, authenticated;

-- The /members Next.js page queries this view filtered by year:
--   SELECT * FROM public_members WHERE year = '2026-27'
--   ORDER BY tier_sort_order DESC, parent_1_name;

-- ===
-- db/migrations/008_rls.sql
-- ===

-- Migration 008: Row-Level Security (RLS)

-- Default: RLS enabled on every table. No policies = no access (deny by default).
-- Then add policies explicitly.

-- -----------------------------------------------------------------------------
-- Base role grants (must precede RLS — RLS filters rows, but only after the
-- role has a table-level privilege at all. Supabase's table UI auto-grants
-- these to anon/authenticated/service_role; raw SQL doesn't, so we do it here.
-- service_role bypasses RLS at the role level, but still needs the table grant.
-- -----------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- Future tables created in this schema inherit the same defaults.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON SEQUENCES TO service_role;


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

-- ===
-- db/migrations/009_storage_policies.sql
-- ===

-- Migration 009: Storage policies (Supabase Storage)

-- Buckets are created via Supabase Studio (already done):
--   news-images, event-images, sponsor-logos, board-photos, site-images, documents
-- All buckets are public so Next.js pages can load referenced URLs without signed URLs.
--
-- These policies govern who can upload/update/delete files in those buckets via
-- storage.objects RLS. Anyone (anon + authenticated) can read; only content_admins
-- can write.

-- All buckets above: anyone can read, only authenticated content_admins can write/delete

CREATE POLICY "Anyone reads public buckets" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id IN ('news-images', 'event-images', 'sponsor-logos', 'board-photos', 'site-images', 'documents'));

CREATE POLICY "Content admins upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id IN ('news-images', 'event-images', 'sponsor-logos', 'board-photos', 'site-images', 'documents')
    AND current_user_has_role('content_admin')
  );

CREATE POLICY "Content admins update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id IN ('news-images', 'event-images', 'sponsor-logos', 'board-photos', 'site-images', 'documents')
    AND current_user_has_role('content_admin')
  );

CREATE POLICY "Content admins delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id IN ('news-images', 'event-images', 'sponsor-logos', 'board-photos', 'site-images', 'documents')
    AND current_user_has_role('content_admin')
  );

-- ===
-- db/migrations/010_seed.sql
-- ===

-- Migration 010: Seed data (run after schema creation, before first deploy)

-- Membership tiers for 2026-27 (from Jeremy's actual Google Form)
INSERT INTO membership_tiers (name, price_cents, description, perks, sort_order, year, requires_tshirt_size, requires_second_tshirt_size, badge_label) VALUES
  ('Free Fan Base!', 0, 'Stay in the loop. Newsletters, updates, community.', '["Newsletter access", "Community updates"]'::jsonb, 1, '2026-27', false, false, null),
  ('Game Day!', 2000, 'Show your support on game day.', '["Listed on website (if you opt in)"]'::jsonb, 2, '2026-27', false, false, 'Most Popular'),
  ('Offense ⇄ Defense!', 5000, 'Step up your support.', '["Listed on website (if you opt in)"]'::jsonb, 3, '2026-27', false, false, null),
  ('Blitz!', 10000, 'Get a Mavericks t-shirt.', '["Listed on website (if you opt in)", "1 Booster t-shirt"]'::jsonb, 4, '2026-27', true, false, null),
  ('Touchdown!', 25000, 'Make a real impact.', '["Listed on website (if you opt in)", "2 Booster t-shirts"]'::jsonb, 5, '2026-27', true, true, null),
  ('Playoffs!', 50000, 'Top-tier supporter.', '["Listed on website (if you opt in)", "2 Booster t-shirts", "VIP recognition"]'::jsonb, 6, '2026-27', true, true, null);

-- Sponsorship tiers for 2026-27 (mirroring Stony Point comp; board ratifies)
INSERT INTO sponsorship_tiers (name, price_cents, description, perks, sort_order, year, badge_label) VALUES
  ('MVP', 500000, 'Top sponsor. Maximum visibility.', '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement at home games", "Game program: Cover ad", "Streaming banner all games", "6x 30-sec audio commercials per game"]'::jsonb, 1, '2026-27', null),
  ('Diamond', 250000, 'Premium sponsor.', '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Full page", "Streaming banner all games", "4x 30-sec audio commercials per game"]'::jsonb, 2, '2026-27', null),
  ('Platinum', 150000, 'High-visibility sponsor.', '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Full page", "Streaming banner all games", "2x 30-sec audio commercials per game"]'::jsonb, 3, '2026-27', 'Recommended'),
  ('Gold', 100000, 'Mid-tier sponsor.', '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Half page", "Streaming recognition"]'::jsonb, 4, '2026-27', null),
  ('Blue', 50000, 'Community sponsor.', '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Quarter page", "Streaming recognition"]'::jsonb, 5, '2026-27', null);

-- Board members for 2026-27 (from booster_club_info.md)
INSERT INTO board_members (name, role, sort_order, year) VALUES
  ('Carol Glinski', 'President', 1, '2026-27'),
  ('Chevon Williams', 'Treasurer', 2, '2026-27'),
  ('Ashley Olson', 'Co-Treasurer', 3, '2026-27'),
  ('Kendra Jalbert', 'VP of Fundraising', 4, '2026-27'),
  ('Shannon Schoepflin', 'VP of Social Events', 5, '2026-27'),
  ('Sylvia Brito', 'VP of Merchandise', 6, '2026-27'),
  ('Jeremy Vest', 'Secretary', 7, '2026-27'),
  ('Debby Mata', 'Communications & Membership Support', 8, '2026-27'),
  ('Monica Woods', 'Social Events Support', 9, '2026-27');

-- Committees (from old SE site, 11 committees)
INSERT INTO committees (name, description, cadence, sort_order) VALUES
  ('Social Media', 'Maintain football website for communications and notifications. Maintain Facebook accounts promoting a positive image of the program.', 'ongoing', 1),
  ('Team Meals', 'Coordinate pregame meals for freshman and JV players. Coordinate Varsity parent team dinners.', 'seasonal', 2),
  ('Membership', 'Maintain membership list. Collect sign-in sheets from meetings and events. Promote the Booster Club.', 'ongoing', 3),
  ('Merchandise', 'Vendors, pricing, design, purchase, inventory. Schedule volunteers to sell at events.', 'ongoing', 4),
  ('Parent Meetings', 'Date, location, volunteers for spring and fall parent meetings.', 'seasonal', 5),
  ('Football Banquet', 'Date, time, venue. Vendor bids. Awards coordination with Sponsor. Volunteer coordination.', 'one_time', 6),
  ('Summer Events', 'Pool location, volunteers, food donations. Advertise via Social Media.', 'one_time', 7),
  ('Meet the Mavs', 'Date with Sponsor/Principal. Coordinate with other booster clubs. Food vendor bids.', 'one_time', 8),
  ('Senior Night', 'Game date set by RRISD. Senior names from Sponsor. Permissions, flower vendors, volunteers.', 'one_time', 9),
  ('Tunnel Stampede', 'Event date. Business sponsorships. Application/payment design. Spirit wear order. Volunteers.', 'one_time', 10),
  ('Fundraisers', 'Oversee any board-determined fundraisers. Coordinate with Social Media.', 'ongoing', 11);

-- site_settings already inserted via INSERT...ON CONFLICT in the table definition (005_settings.sql)

-- ===
-- db/migrations/011_football_pivot_types.sql
-- ===

-- Migration 011: Football pivot enum types

CREATE TYPE team_level AS ENUM ('varsity', 'jv', 'freshman');
CREATE TYPE home_or_away AS ENUM ('home', 'away', 'neutral');
CREATE TYPE game_result_status AS ENUM ('scheduled', 'final', 'cancelled', 'postponed', 'tbd');
CREATE TYPE coach_role_category AS ENUM ('head', 'coordinator', 'position_coach', 'trainer', 'staff');
CREATE TYPE resource_section AS ENUM ('registration_forms', 'communications', 'resources', 'stadiums', 'other');

-- ===
-- db/migrations/012_football_pivot_tables.sql
-- ===

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

-- ===
-- db/migrations/013_players_table.sql
-- ===

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

-- ===
-- db/migrations/014_site_settings_additions.sql
-- ===

-- Migration 014: site_settings additions for football-first home page and footer

ALTER TABLE site_settings
  ADD COLUMN maxpreps_team_url text DEFAULT 'https://www.maxpreps.com/tx/austin/mcneil-mavericks/football/',
  ADD COLUMN season_label text,
  ADD COLUMN season_opener_date timestamptz,
  ADD COLUMN next_game_override text,
  ADD COLUMN current_year text NOT NULL DEFAULT '2026-27';

-- ===
-- db/migrations/015_football_pivot_triggers.sql
-- ===

-- Migration 015: touch_updated_at triggers for the new football-pivot tables

CREATE TRIGGER touch_games BEFORE UPDATE ON games FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_rosters BEFORE UPDATE ON rosters FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_coaches BEFORE UPDATE ON coaches FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_resource_links BEFORE UPDATE ON resource_links FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ===
-- db/migrations/016_football_pivot_rls.sql
-- ===

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

-- ===
-- db/migrations/017_players_rls.sql
-- ===

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

-- ===
-- db/migrations/018_football_pivot_seed.sql
-- ===

-- Migration 018: Football pivot seed data (rosters stubs, Coach Wallin, resource_links scaffolding)

-- Block 1: rosters — three stubs for 2026-27.
-- team_designation column does not exist yet (added in 019); freshman 'Green'
-- designation will be backfilled there.
INSERT INTO rosters (year, team_level, body, source_note) VALUES
  ('2026-27', 'varsity',  '', 'Awaiting roster from coaching staff'),
  ('2026-27', 'jv',       '', 'Awaiting roster from coaching staff'),
  ('2026-27', 'freshman', '', 'Awaiting roster from coaching staff');

-- Block 2: coaches — Coach Wallin (still on staff, no longer head coach).
INSERT INTO coaches (year, name, role, role_category, sort_order, active) VALUES
  ('2026-27', 'Coach Wallin', 'Position Coach', 'position_coach', 10, true);

-- Block 3: resource_links — section scaffolding plus known-good rows.
-- SportsYou URL/description per schema_v2_addendum.md section 4 (not the original '#').
INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order) VALUES
  -- Registration & Forms
  ('registration_forms', 'Aktivate (Athletic Registration)', 'https://www.aktivate.com/', 'Required online registration for all athletes. Replaces the old RankOne system.', 'external', 1),
  ('registration_forms', 'UIL Forms', 'https://www.uiltexas.org/athletics/forms', 'University Interscholastic League required forms for participation.', 'external', 2),
  ('registration_forms', 'RRISD Athletic Forms', 'https://roundrockisd.org/athletics', 'Round Rock ISD athletic department forms and policies.', 'external', 3),
  -- Communications
  ('communications', 'HUDL', 'https://www.hudl.com/jointeam', 'Team video and stats platform. Team code provided by coaching staff.', 'external', 1),
  ('communications', 'SportsYou (Team Messaging)', 'https://www.sportsyou.com/', 'Team messaging app for parents and players. Use the access code from the SportsYou invite page in the SE capture, or contact the booster club at boosters@mcneilmavericks.org.', 'external', 2),
  -- Stadiums
  ('stadiums', 'Kelly Reeves Athletic Complex', 'https://maps.google.com/?q=Kelly+Reeves+Athletic+Complex+Round+Rock+TX', 'McNeil home games. 10211 W Parmer Ln, Austin, TX 78717.', 'external', 1);

-- ===
-- db/migrations/018b_coaches_seed_hale.sql
-- ===

-- Migration 018b: Seed Michael Hale (Defensive Coordinator) on coaches

INSERT INTO coaches (year, name, role, role_category, email, sort_order, active) VALUES
  ('2026-27', 'Michael Hale', 'Defensive Coordinator', 'coordinator', 'Michael_Hale@roundrockisd.org', 5, true);

-- ===
-- db/migrations/019_team_designation.sql
-- ===

-- Migration 019: Add team_designation to games and rosters; replace rosters uniqueness
-- with a COALESCE-based unique index (varsity/JV use NULL, freshman uses 'Green'/'Blue').

BEGIN;

ALTER TABLE games ADD COLUMN team_designation text;
ALTER TABLE rosters ADD COLUMN team_designation text;

ALTER TABLE rosters DROP CONSTRAINT rosters_year_team_level_key;

CREATE UNIQUE INDEX idx_rosters_year_level_designation
  ON rosters (year, team_level, COALESCE(team_designation, ''));

UPDATE rosters SET team_designation = 'Green'
  WHERE year = '2026-27' AND team_level = 'freshman';

COMMIT;

-- ===
-- db/migrations/020_practice_schedules.sql
-- ===

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

-- ===
-- db/migrations/021_practice_schedules_rls.sql
-- ===

-- Migration 021: RLS policies for practice_schedules (same pattern as rosters)

ALTER TABLE practice_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone reads active practice schedules" ON practice_schedules
  FOR SELECT TO anon USING (active = true);

CREATE POLICY "Authenticated read all practice schedules" ON practice_schedules
  FOR SELECT TO authenticated USING (current_user_has_role('content_admin'));

CREATE POLICY "Content admins write practice schedules" ON practice_schedules
  FOR INSERT TO authenticated WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins update practice schedules" ON practice_schedules
  FOR UPDATE TO authenticated USING (current_user_has_role('content_admin'))
  WITH CHECK (current_user_has_role('content_admin'));

CREATE POLICY "Content admins delete practice schedules" ON practice_schedules
  FOR DELETE TO authenticated USING (current_user_has_role('content_admin'));

-- ===
-- db/migrations/022_sponsorship_inquiries.sql
-- ===

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

-- ===
-- db/migrations/023_site_settings_socials.sql
-- ===

-- Migration 023: Rename facebook_group_url -> facebook_boosters_url and add
-- football/X social fields. Addendum 2 narrative says rename (preserves the
-- seeded value); the SQL block in that section that ADDs facebook_boosters_url
-- is a copy-paste error.

BEGIN;

ALTER TABLE site_settings RENAME COLUMN facebook_group_url TO facebook_boosters_url;
ALTER TABLE site_settings ADD COLUMN facebook_football_url text;
ALTER TABLE site_settings ADD COLUMN x_football_url text;
ALTER TABLE site_settings ADD COLUMN x_boosters_url text;

COMMIT;

-- ===
-- db/migrations/023b_site_settings_freshman_blue.sql
-- ===

-- Migration 023b: site_settings.freshman_has_blue toggle.
-- Per schema_content_v2_addendum3.md section 2. Admin flips this to enable
-- the freshman Blue team alongside the default Green.

ALTER TABLE site_settings
  ADD COLUMN freshman_has_blue boolean NOT NULL DEFAULT false;

-- ===
-- db/migrations/024_practice_schedules_seed.sql
-- ===

-- Migration 024: Seed practice_schedules with three team-level stubs for 2026-27.

INSERT INTO practice_schedules (year, team_level, body, source_note) VALUES
  ('2026-27', 'varsity',  '', 'Awaiting practice schedule from coaching staff'),
  ('2026-27', 'jv',       '', 'Awaiting practice schedule from coaching staff'),
  ('2026-27', 'freshman', '', 'Awaiting practice schedule from coaching staff');

-- ===
-- db/migrations/025_site_settings_mailing_address.sql
-- ===

-- Migration 025: Backfill site_settings.mailing_address into a migration so a
-- fresh DB rebuild reproduces the live two-line render. Idempotent: re-runs
-- as a no-op once the value is set. Completes the 4b live-seed carryover.

UPDATE site_settings
SET mailing_address = E'#412, 6001 W Parmer Ln, Suite 370\nAustin, TX 78727'
WHERE id = 1
  AND (mailing_address IS NULL OR mailing_address = '');

-- ===
-- db/migrations/026_coach_photos_storage_policies.sql
-- ===

-- Migration 026: Storage policies for the coach-photos bucket.
--
-- Bucket is created via Supabase Studio (per schema_v2.md §"What does NOT change"):
--   coach-photos: public, max 5MB, image/png + image/jpeg + image/webp
--
-- Mirrors the 4-policy pattern from 009_storage_policies.sql, scoped to bucket_id
-- = 'coach-photos' so it can diverge from the shared image buckets later if needed
-- (e.g., RRISD consent rules for coach photos vs. parent-volunteer board photos).

CREATE POLICY "Anyone reads coach photos" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'coach-photos');

CREATE POLICY "Content admins upload coach photos" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'coach-photos'
    AND current_user_has_role('content_admin')
  );

CREATE POLICY "Content admins update coach photos" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'coach-photos'
    AND current_user_has_role('content_admin')
  );

CREATE POLICY "Content admins delete coach photos" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'coach-photos'
    AND current_user_has_role('content_admin')
  );

-- ===
-- db/migrations/027_seed_test_games.sql
-- ===

-- Migration 027: test seed for `games` table (slice 4 of Commit B).
--
-- Purpose
--   Slice 4 needs rendered rows on every /schedule/games/* page so the table
--   render and home-tint / result-cell / Watch-icon logic can be exercised
--   on Vercel preview. There is no admin CRUD yet (lands in Step 7b or 13),
--   so we seed plausible Central Texas opponents and result states.
--
-- Coverage
--   varsity:        5 rows (final win, final loss, scheduled, cancelled, tbd)
--   jv:             2 rows (final win, scheduled)
--   freshman/Green: 2 rows (scheduled home, scheduled away)
--   Total: 9 rows, all year='2026-27'.
--
-- Cleanup
--   When real games are entered via admin CRUD (Step 7b or 13), drop the
--   whole test set in one shot:
--       DELETE FROM games WHERE year = '2026-27';
--   This whole row set is intended to be replaced, not merged with, real data.

BEGIN;

-- Varsity (team_designation NULL)
INSERT INTO games (
  year, team_level, team_designation,
  opponent, opponent_url,
  game_date,
  location, location_url,
  home_or_away,
  our_score, their_score, result_status,
  watch_url, notes
) VALUES
  -- 1. Final, win, home, watch_url, Homecoming
  (
    '2026-27', 'varsity', NULL,
    'Hutto', NULL,
    '2026-09-25 19:30:00 America/Chicago'::timestamptz,
    'Kelly Reeves Athletic Complex', NULL,
    'home',
    35, 14, 'final',
    'https://www.youtube.com/watch?v=test-mcneil-hutto', 'Homecoming'
  ),
  -- 2. Final, loss, away, no notes
  (
    '2026-27', 'varsity', NULL,
    'Cedar Ridge', NULL,
    '2026-09-04 19:30:00 America/Chicago'::timestamptz,
    'Cedar Ridge High School', NULL,
    'away',
    21, 28, 'final',
    NULL, NULL
  ),
  -- 3. Scheduled, home, opponent_url + location_url
  (
    '2026-27', 'varsity', NULL,
    'Round Rock', 'https://roundrockfootball.example.com/',
    '2026-10-09 19:30:00 America/Chicago'::timestamptz,
    'Kelly Reeves Athletic Complex',
    'https://maps.google.com/?q=Kelly+Reeves+Athletic+Complex+Round+Rock+TX',
    'home',
    NULL, NULL, 'scheduled',
    NULL, NULL
  ),
  -- 4. Cancelled, away
  (
    '2026-27', 'varsity', NULL,
    'Vista Ridge', NULL,
    '2026-10-16 19:30:00 America/Chicago'::timestamptz,
    'Vista Ridge High School', NULL,
    'away',
    NULL, NULL, 'cancelled',
    NULL, NULL
  ),
  -- 5. TBD, home
  (
    '2026-27', 'varsity', NULL,
    'Westwood', NULL,
    '2026-10-30 19:30:00 America/Chicago'::timestamptz,
    'Kelly Reeves Athletic Complex', NULL,
    'home',
    NULL, NULL, 'tbd',
    NULL, NULL
  );

-- JV (team_designation NULL)
INSERT INTO games (
  year, team_level, team_designation,
  opponent, game_date,
  location, home_or_away,
  our_score, their_score, result_status
) VALUES
  -- 1. Final, win, home
  (
    '2026-27', 'jv', NULL,
    'Hutto',
    '2026-09-17 18:00:00 America/Chicago'::timestamptz,
    'Kelly Reeves Athletic Complex', 'home',
    24, 7, 'final'
  ),
  -- 2. Scheduled, away
  (
    '2026-27', 'jv', NULL,
    'Stony Point',
    '2026-10-01 18:00:00 America/Chicago'::timestamptz,
    'Stony Point High School', 'away',
    NULL, NULL, 'scheduled'
  );

-- Freshman Green
INSERT INTO games (
  year, team_level, team_designation,
  opponent, game_date,
  location, home_or_away,
  result_status
) VALUES
  -- 1. Scheduled, home
  (
    '2026-27', 'freshman', 'Green',
    'Cedar Ridge',
    '2026-09-17 16:30:00 America/Chicago'::timestamptz,
    'Kelly Reeves Athletic Complex', 'home',
    'scheduled'
  ),
  -- 2. Scheduled, away
  (
    '2026-27', 'freshman', 'Green',
    'Round Rock',
    '2026-10-01 16:30:00 America/Chicago'::timestamptz,
    'Round Rock High School', 'away',
    'scheduled'
  );

COMMIT;

-- ===
-- db/migrations/028_fix_seed_test_games_urls.sql
-- ===

-- Migration 028: replace .example.com placeholder URLs from 027 with real
-- MaxPreps and venue URLs. Throwaway test data; admin CRUD will replace these
-- rows entirely (Step 7b or 13). Convention: opponent_url points to the
-- opponent's MaxPreps team page.

BEGIN;

UPDATE games
SET opponent_url = 'https://www.maxpreps.com/tx/round-rock/round-rock-dragons/football/'
WHERE year = '2026-27'
  AND team_level = 'varsity'
  AND opponent = 'Round Rock'
  AND opponent_url = 'https://roundrockfootball.example.com/';

COMMIT;

-- ===
-- db/migrations/029_seed_test_varsity_roster.sql
-- ===

-- Migration 029: TEST DATA. Lights up the public roster render with the
-- 2025-26 MaxPreps varsity snapshot, attached to the 2026-27 varsity
-- roster row so the page has real-looking content for staging review.
--
-- Remove before public cutover. Tracked in followups.md.
-- Cleanup path: DELETE FROM players WHERE roster_id =
--   (SELECT id FROM rosters WHERE year='2026-27' AND team_level='varsity'
--    AND team_designation IS NULL AND active=true);
--
-- Source: docs/mcneil_varsity_roster_2025-26.txt (27 players).

BEGIN;

INSERT INTO players (
  roster_id,
  jersey_number, first_name, last_name,
  position, grade, height, weight,
  sort_order, active
)
SELECT
  r.id,
  v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, v.height, v.weight,
  v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('0',  'Aden',     'Taylor',     NULL,      'Sr.', '5''11"', 175, 1),
  ('1',  'Bryce',    'Wilson',     'K, P',    'Sr.', '6''2"',  220, 2),
  ('2',  'Sean',     'Crowe',      'FS',      'Sr.', NULL,     NULL::int, 3),
  ('3',  'Brian',    'Perkins',    'WR, DB',  'Sr.', NULL,     NULL::int, 4),
  ('4',  'Isaiah',   'Jones',      'CB, WR',  'Jr.', '6''2"',  185, 5),
  ('5',  'Jarell',   'Gary Jr',    'WR, QB',  'Sr.', '6''0"',  190, 6),
  ('7',  'Ja Corian','Hubbard',    'DL, RB',  'Sr.', '6''2"',  250, 7),
  ('8',  'Marshall', 'Holland',    'MLB, OLB','Sr.', '5''10"', 215, 8),
  ('9',  'Zach',     'Christie',   'WR',      'Sr.', '6''2"',  188, 9),
  ('10', 'Jadon',    'Sultz',      'QB',      'Sr.', '6''1"',  200, 10),
  ('11', 'Calvin',   'Cervini',    'QB, CB',  'Sr.', '6''4"',  180, 11),
  ('14', 'DJ',       'Vasquez',    'DB',      'Sr.', NULL,     NULL::int, 12),
  ('15', 'Tyson',    'Cox',        'OLB, SS', 'Jr.', '5''10"', 190, 13),
  ('18', 'Kaden',    'Kearney',    'DB',      'So.', NULL,     NULL::int, 14),
  ('20', 'Keyvon',   'Myers',      'CB',      'Sr.', '6''0"',  170, 15),
  ('21', 'Johnny',   'McFarland',  'DB',      'Sr.', NULL,     NULL::int, 16),
  ('22', 'Adien',    'Murray',     'DB',      'Sr.', NULL,     NULL::int, 17),
  ('23', 'Zylen',    'Hall',       'RB',      'Jr.', '5''7"',  155, 18),
  ('24', 'Malachi',  'Golden',     'DB',      'Sr.', NULL,     NULL::int, 19),
  ('25', 'Jamal',    'Harris',     'RB',      'Sr.', NULL,     NULL::int, 20),
  ('32', 'Michael',  'Jones',      'OLB',     'Sr.', '6''1"',  190, 21),
  ('34', 'Skyler',   'Eaves',      'OLB',     'Sr.', '6''0"',  172, 22),
  ('38', 'Ford',     'Askins',     'LB',      'Jr.', NULL,     NULL::int, 23),
  ('42', 'Jacorian', 'Hubbard',    'DE',      'Sr.', '6''0"',  200, 24),
  ('46', 'Nkume',    'Nwosu',      'DL',      'Sr.', NULL,     NULL::int, 25),
  ('53', 'Isaiah',   'Escalante',  'C, DE',   'Sr.', '6''0"',  208, 26),
  ('82', 'Bowen',    'Wheatley',   'TE',      'Sr.', '6''3"',  215, 27)
) AS v(jersey_number, first_name, last_name, position, grade, height, weight, sort_order)
WHERE r.year = '2026-27'
  AND r.team_level = 'varsity'
  AND r.team_designation IS NULL
  AND r.active = true;

COMMIT;

-- ===
-- db/migrations/030_split_year_relabel_football.sql
-- ===

-- Migration 030: Split site_settings year fields and relabel football
-- seed rows from "2026-27" to "2025-26".
--
-- Schema add: site_settings.current_board_year (governs board data).
-- site_settings.current_year now governs only football data (rosters,
-- practice_schedules, coaches, games). Board year is decoupled because
-- the operating board year and the football season being displayed are
-- on different cadences.
--
-- Data relabel: rosters, practice_schedules, coaches, games move from
-- "2026-27" -> "2025-26" to match the actual data we have (the season
-- just completed). board_members stays at "2026-27" — current board is
-- already the 2026-27 board. membership_tiers, sponsorship_tiers, and
-- every other year-stamped table are untouched.
--
-- Idempotent: each UPDATE filters by the current value, so re-running
-- against a database that has already moved forward is a no-op.
-- Reversible: an inverse migration can flip values back; the new
-- column can be dropped if needed (no data depends on it before this
-- migration ships).

BEGIN;

ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS current_board_year text NOT NULL DEFAULT '2026-27';

UPDATE site_settings      SET current_year = '2025-26' WHERE current_year = '2026-27';
UPDATE rosters            SET year         = '2025-26' WHERE year         = '2026-27';
UPDATE practice_schedules SET year         = '2025-26' WHERE year         = '2026-27';
UPDATE coaches            SET year         = '2025-26' WHERE year         = '2026-27';
UPDATE games              SET year         = '2025-26' WHERE year         = '2026-27';

COMMIT;

-- ===
-- db/migrations/031_seed_2025_jv_freshman_rosters.sql
-- ===

-- Migration 031: TEST DATA for the 2025-26 review period.
-- Adds the JV (65 players), Freshman Green (19), and Freshman Blue (22)
-- rosters from the 2025 PDFs in docs/. Creates the Freshman Blue
-- rosters row (Green already seeded by 018 + 019). Flips
-- site_settings.freshman_has_blue=true so the Blue page renders and
-- the header dropdown shows the Blue entry.
--
-- 8 freshman players are uncolored in the source PDF (no Green/Blue
-- assignment). They are NOT seeded; flagged in followups.md for coach
-- clarification. 1 freshman row in the PDF has neither jersey# nor
-- name (corrupt source row) — skipped.
--
-- Class column: source values 10 and 11 map to "So." and "Jr." for
-- display consistency with the varsity seed. Freshman = "Fr.".
--
-- Position: stored verbatim from source (e.g., "WR/DB", "OL/DL").
-- Height/weight not provided by source -> NULL.
--
-- Cleanup before public cutover:
--   DELETE FROM players WHERE roster_id IN (
--     SELECT id FROM rosters WHERE year='2025-26' AND team_level IN ('jv','freshman')
--   );
--   DELETE FROM rosters WHERE year='2025-26' AND team_level='freshman' AND team_designation='Blue';

BEGIN;

-- 1. Add the Freshman Blue rosters row (Green already exists from migration 018+019).
INSERT INTO rosters (year, team_level, team_designation, body, source_note, active)
VALUES ('2025-26', 'freshman', 'Blue', '', 'Awaiting roster from coaching staff', true);

-- 2. Flip the Blue flag so /roster/freshman/blue + /schedule/games/freshman/blue render.
UPDATE site_settings SET freshman_has_blue = true WHERE freshman_has_blue = false;

-- 3. JV roster: 65 players.
INSERT INTO players (
  roster_id, jersey_number, first_name, last_name,
  position, grade, height, weight, sort_order, active
)
SELECT
  r.id, v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, NULL, NULL::int, v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('0',  'Kees',                'Glinski',          'TE',       'Jr.',  1),
  ('1',  'Jace',                'Servantez',        'QB',       'So.',  2),
  ('2',  'Case',                'Keough',           'DB',       'So.',  3),
  ('3',  'Evan',                'Vest',             'DB',       'Jr.',  4),
  ('4',  'Hudson',              'Cronin',           'WR',       'So.',  5),
  ('5',  'Cicero',              'Stroman',          'DL',       'So.',  6),
  ('6',  'Silas',               'Carter',           'DB',       'So.',  7),
  ('7',  'Kieran',              'Jalbert',          'TE',       'So.',  8),
  ('8',  'Orion',               'Covault',          'QB',       'Jr.',  9),
  ('9',  'Aiden',               'Creque',           'WR',       'Jr.', 10),
  ('10', 'Keston',              'Variste',          'WR',       'So.', 11),
  ('11', 'Angel',               'Gudino De Leon',   'LB',       'Jr.', 12),
  ('12', 'Jatavius',            'Washington',       'QB',       'Jr.', 13),
  ('13', 'Eli',                 'Weaver',           'DB',       'Jr.', 14),
  ('14', 'Alonzo',              'Mata',             'WR',       'So.', 15),
  ('15', 'Hendrix',             'Boston',           'DB',       'Jr.', 16),
  ('16', 'Logan',               'Moeller',          'QB',       'So.', 17),
  ('17', 'Jude',                'Montez',           'WR',       'Jr.', 18),
  ('18', 'Ka''Darious',         'Montgomery',       'DB',       'So.', 19),
  ('19', 'Owen',                'Baumann',          'DB',       'So.', 20),
  ('20', 'Chance',              'Woodward',         'WR',       'Jr.', 21),
  ('21', 'Gabe',                'Parker',           'WR',       'So.', 22),
  ('22', 'Akmal',               'Waqif',            'LB',       'So.', 23),
  ('23', 'Omar',                'Aviles',           'LB',       'So.', 24),
  ('24', 'Tramaurie',           'Mayweather',       'WR',       'Jr.', 25),
  ('25', 'Owen',                'Mazorra',          'WR',       'So.', 26),
  ('26', 'Mcharo',              'Criswell',         'RB',       'Jr.', 27),
  ('27', 'Richardo',            'Gonzalez jr.',     'DB',       'So.', 28),
  ('28', 'Michael',              'Sieber',          'K',        'Jr.', 29),
  ('30', 'Ryan',                 'Amin',            'LB',       'Jr.', 30),
  ('31', 'Jordan',               'Deshay',          'RB',       'So.', 31),
  ('32', 'Aston',                'Sampayo',         'DB',       'So.', 32),
  ('33', 'Zji''Sean',            'Thomas',          'WR',       'So.', 33),
  ('34', 'Reid',                 'Gordon',          'DB',       'So.', 34),
  ('35', 'Ben',                  'Eaton',           'DB',       'So.', 35),
  ('36', 'Ford',                 'Askins',          'LB',       'Jr.', 36),
  ('37', 'Dylan',                'Woods',           'RB',       'Jr.', 37),
  ('38', 'Maxwell',              'Leger',           'DB',       'So.', 38),
  ('40', 'Akiereon',             'Chatman',         'DB',       'So.', 39),
  ('42', 'Quamera',              'Sutherland',      'LB',       'Jr.', 40),
  ('43', 'Aymane',               'El Anssari',      'K',        'Jr.', 41),
  ('45', 'James',                'Evans',           'DL',       'Jr.', 42),
  ('46', 'Oliver',               'Weisbrod',        'LB',       'So.', 43),
  ('48', 'Zackary',              'Hauser',          'DL',       'Jr.', 44),
  ('51', 'Joaquin',              'Mata',            'DL',       'Jr.', 45),
  ('52', 'Montana',              'Burks',           'LB',       'Jr.', 46),
  ('54', 'Nathan',               'Park',            'DL',       'So.', 47),
  ('55', 'Jayden',               'Fabien',          'DL',       'So.', 48),
  ('56', 'Juan',                 'Ramirez',         'OL',       'So.', 49),
  ('61', 'Gianni',               'Aviles',          'DL',       'Jr.', 50),
  ('62', 'Garrett',              'Root',            'OL',       'Jr.', 51),
  ('63', 'Leonardo',             'Soto',            'OL',       'Jr.', 52),
  ('66', 'Aiden',                'Ross',            'OL',       'So.', 53),
  ('70', 'Jackson',              'Miller',          'DL',       'So.', 54),
  ('71', 'D''Zion',              'Taylor',          'OL',       'So.', 55),
  ('72', 'Daniel',               'Christensen',     'OL',       'So.', 56),
  ('75', 'Preston',              'Higgins',         'OL',       'So.', 57),
  ('78', 'Wesley',               'Davis',           'OL',       'So.', 58),
  ('79', 'Soumith',              'Veeragoni',       'OL',       'So.', 59),
  ('80', 'Rashawn',              'McDowell',        'WR',       'So.', 60),
  ('81', 'Amery',                'Schoepflin',      'TE',       'Jr.', 61),
  ('82', 'Orion',                'Smith',           'WR',       'So.', 62),
  ('83', 'Brendyn',              'Brown',           'WR',       'Jr.', 63),
  ('86', 'Tramaurie',            'Mayweather',      'TE',       'Jr.', 64),
  ('88', 'Derrick',              'WIlliams',        'DL',       'So.', 65)
) AS v(jersey_number, first_name, last_name, position, grade, sort_order)
WHERE r.year = '2025-26'
  AND r.team_level = 'jv'
  AND r.team_designation IS NULL
  AND r.active = true;

-- 4. Freshman Green: 19 players.
INSERT INTO players (
  roster_id, jersey_number, first_name, last_name,
  position, grade, height, weight, sort_order, active
)
SELECT
  r.id, v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, NULL, NULL::int, v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('1',  'Brayden',  'Norman',                'WR/DB', 'Fr.',  1),
  ('2',  'Ade',      'Carter',                'WR/DB', 'Fr.',  2),
  ('5',  'Kai',      'Brito',                 'QB/DB', 'Fr.',  3),
  ('6',  'William',  'Miller',                'QB/DB', 'Fr.',  4),
  ('7',  'Matheo',   'Ramirez-Escamilla',     'QB/DB', 'Fr.',  5),
  ('8',  'Josiah',   'Scott',                 'WR/DB', 'Fr.',  6),
  ('11', 'TreyVon',  'Cargill',               'WR/DB', 'Fr.',  7),
  ('12', 'Jeremy',   'Powell',                'TE/LB', 'Fr.',  8),
  ('13', 'Jeramiyah','Harris',                'RB/LB', 'Fr.',  9),
  ('15', 'TK',       'Keller',                'RB/LB', 'Fr.', 10),
  ('20', 'Antonio',  'Showels',               'WR/LB', 'Fr.', 11),
  ('26', 'Remiel',   'Soto',                  'TE/DB', 'Fr.', 12),
  ('30', 'Logan',    'Gurrola',               'WR/LB', 'Fr.', 13),
  ('38', 'Anjrue',   'Williams',              'QB/LB', 'Fr.', 14),
  ('52', 'Caleb',    'Woodward',              'OL/DL', 'Fr.', 15),
  ('67', 'Caleb',    'Cox',                   'OL/DL', 'Fr.', 16),
  ('75', 'Charles',  'Lewis',                 'OL/DL', 'Fr.', 17),
  ('76', 'Jace',     'Hicks',                 'OL/DL', 'Fr.', 18),
  ('84', 'Jake',     'Thomas',                'WR/DB', 'Fr.', 19)
) AS v(jersey_number, first_name, last_name, position, grade, sort_order)
WHERE r.year = '2025-26'
  AND r.team_level = 'freshman'
  AND r.team_designation = 'Green'
  AND r.active = true;

-- 5. Freshman Blue: 22 players.
INSERT INTO players (
  roster_id, jersey_number, first_name, last_name,
  position, grade, height, weight, sort_order, active
)
SELECT
  r.id, v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, NULL, NULL::int, v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('9',  'Zane',     'Valenzuela',            'WR/DB', 'Fr.',  1),
  ('10', 'Jake',     'Saenz',                 'WR/DB', 'Fr.',  2),
  ('17', 'Owen',     'Richardson',            'WR/DB', 'Fr.',  3),
  ('18', 'Jackson',  'James',                 'WR/DB', 'Fr.',  4),
  ('21', 'Bryant',   'Smith',                 'RB/DB', 'Fr.',  5),
  ('22', 'Michael',  'Menchaca',              'WR/DB', 'Fr.',  6),
  ('23', 'Dante',    'McBeath',               'RB/LB', 'Fr.',  7),
  ('25', 'Angel',    'Meza',                  'RB/DL', 'Fr.',  8),
  ('28', 'Jasiah',   'Harris',                'WR/DB', 'Fr.',  9),
  ('33', 'Eli',      'Thrift',                'WR/DB', 'Fr.', 10),
  ('35', 'Ricky',    'Brown',                 'WR/DB', 'Fr.', 11),
  ('36', 'Isaac',    'Chandy',                'WR/DB', 'Fr.', 12),
  ('40', 'Gabriel',  'Berney',                'TE/DB', 'Fr.', 13),
  ('44', 'Iger',     'Mallvichko',            'TE/LB', 'Fr.', 14),
  ('45', 'Da''Mauri','Barfield',              'RB/DB', 'Fr.', 15),
  ('51', 'Jayden',   'Harris',                'OL/DL', 'Fr.', 16),
  ('54', 'Joseph',   'Bowles',                'OL/DL', 'Fr.', 17),
  ('60', 'Isaiah',   'Arias-Faulkner',        'OL/DL', 'Fr.', 18),
  ('61', 'Leland',   'Boston',                'OL/LB', 'Fr.', 19),
  ('77', 'Kaeden',   'Frazier',               'OL/DL', 'Fr.', 20),
  ('81', 'Alex',     'Pugliese',              'WR/DB', 'Fr.', 21),
  ('85', 'Riley',    'Cortez',                'WR/DB', 'Fr.', 22)
) AS v(jersey_number, first_name, last_name, position, grade, sort_order)
WHERE r.year = '2025-26'
  AND r.team_level = 'freshman'
  AND r.team_designation = 'Blue'
  AND r.active = true;

COMMIT;

-- ===
-- db/migrations/032_seed_2025_schedule.sql
-- ===

-- Migration 032: TEST DATA. Replace the 9 throwaway placeholder games
-- (seeded by 027/028, then relabeled to 2025-26 by 030) with the real
-- 2025 McNeil schedule from docs/2025 Football schedule.pdf.
--
-- 46 rows total: V=11, JV=11, Freshman Blue=12, Freshman Green=12.
-- BYE weeks (Oct 17 V / Oct 16 JV+F) are skipped because the schema
-- requires opponent NOT NULL. Cedar Park (Aug 16, freshman) carries
-- notes='Scrimmage' per the schema_v2_addendum operational note.
--
-- Decisions:
-- - result_status='scheduled' for all games. The 2025 season is over
--   but the PDF carries no scores; honest representation is "we have
--   the schedule, not the results." Admin CRUD will backfill.
-- - opponent_url and location_url NULL on every row. Admin populates.
-- - Freshman Blue plays 5:00 PM, Freshman Green plays 6:30 PM on the
--   ten split-time games (per the schedule footer). Aug 16 Cedar Park
--   scrimmage and Aug 21 Anderson are duplicated across both teams at
--   the single advertised time so both /freshman/blue and
--   /freshman/green pages render them.
-- - Times use America/Chicago. CDT through Nov 2, 2025; CST from
--   Nov 3 onward. Nov 6 (JV+F Hutto) and Nov 7 (V Hutto) fall in CST.
-- - Notes: 'Homecoming' (V Sep 12 Westwood), 'Senior Night' (V Oct 31
--   Manor), 'Scrimmage' (F Aug 16 Cedar Park). District (*) markers
--   from the PDF are ignored — no column for it.
--
-- Cleanup before public cutover:
--   DELETE FROM games WHERE year='2025-26';

BEGIN;

-- 1. Clear the 9 throwaway placeholder games from migrations 027+028.
DELETE FROM games WHERE year = '2025-26';

-- 2. Insert the real 2025 V/JV schedule.
INSERT INTO games (
  year, team_level, team_designation,
  opponent, opponent_url, game_date, location, location_url,
  home_or_away, result_status, our_score, their_score,
  watch_url, notes, featured
) VALUES
  -- VARSITY (11)
  ('2025-26', 'varsity', NULL, 'Anderson',                 NULL, '2025-08-21 19:30 America/Chicago', 'House Park',       NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Weiss High School',        NULL, '2025-08-28 19:00 America/Chicago', 'The Pfield',       NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Lake Belton High School',  NULL, '2025-09-04 19:00 America/Chicago', 'Gupton Stadium',   NULL, 'home',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Westwood High School',     NULL, '2025-09-12 19:00 America/Chicago', 'KRAC',             NULL, 'home',    'scheduled', NULL, NULL, NULL, 'Homecoming',   false),
  ('2025-26', 'varsity', NULL, 'Round Rock High School',   NULL, '2025-09-19 19:00 America/Chicago', 'Dragon Stadium',   NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Stony Point High School',  NULL, '2025-09-26 19:00 America/Chicago', 'Dragon Stadium',   NULL, 'home',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Vandegrift High School',   NULL, '2025-10-03 19:00 America/Chicago', 'Monroe Stadium',   NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Vista Ridge High School',  NULL, '2025-10-10 19:00 America/Chicago', 'KRAC',             NULL, 'home',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Cedar Ridge High School',  NULL, '2025-10-24 19:00 America/Chicago', 'KRAC',             NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'varsity', NULL, 'Manor High School',        NULL, '2025-10-31 19:00 America/Chicago', 'Dragon Stadium',   NULL, 'home',    'scheduled', NULL, NULL, NULL, 'Senior Night', false),
  ('2025-26', 'varsity', NULL, 'Hutto High School',        NULL, '2025-11-07 19:00 America/Chicago', 'Memorial Stadium', NULL, 'away',    'scheduled', NULL, NULL, NULL, NULL, false),

  -- JV (11)
  ('2025-26', 'jv', NULL, 'Anderson',                 NULL, '2025-08-21 18:00 America/Chicago', 'House Park',        NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Weiss High School',        NULL, '2025-08-27 18:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Lake Belton High School',  NULL, '2025-09-03 17:00 America/Chicago', 'Lake Belton HS',    NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Westwood High School',     NULL, '2025-09-11 18:00 America/Chicago', 'Westwood HS',       NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Round Rock High School',   NULL, '2025-09-18 18:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Stony Point High School',  NULL, '2025-09-25 17:00 America/Chicago', 'Stony Point HS',    NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Vandegrift High School',   NULL, '2025-10-02 18:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Vista Ridge High School',  NULL, '2025-10-09 18:00 America/Chicago', 'Vista Ridge HS',    NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Cedar Ridge High School',  NULL, '2025-10-23 18:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Manor High School',        NULL, '2025-10-30 18:00 America/Chicago', 'Manor HS',          NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'jv', NULL, 'Hutto High School',        NULL, '2025-11-06 18:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),

  -- FRESHMAN BLUE (12) — Aug 16 + Aug 21 combined-time; the rest at 5:00 PM
  ('2025-26', 'freshman', 'Blue',  'Cedar Park High School',    NULL, '2025-08-16 10:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, 'Scrimmage', false),
  ('2025-26', 'freshman', 'Blue',  'Anderson',                  NULL, '2025-08-21 18:00 America/Chicago', 'House Park',        NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Weiss High School',         NULL, '2025-08-27 17:00 America/Chicago', 'Weiss HS',          NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Lake Belton High School',   NULL, '2025-09-03 17:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Westwood High School',      NULL, '2025-09-11 17:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Round Rock High School',    NULL, '2025-09-18 17:00 America/Chicago', 'Round Rock HS',     NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Stony Point High School',   NULL, '2025-09-25 17:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Vandegrift High School',    NULL, '2025-10-02 17:00 America/Chicago', 'Vandegrift HS',     NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Vista Ridge High School',   NULL, '2025-10-09 17:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Cedar Ridge High School',   NULL, '2025-10-23 17:00 America/Chicago', 'Cedar Ridge HS',    NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Manor High School',         NULL, '2025-10-30 17:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Blue',  'Hutto High School',         NULL, '2025-11-06 17:00 America/Chicago', 'Hutto HS',          NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),

  -- FRESHMAN GREEN (12) — same opponents/sites as Blue; split-time games at 6:30 PM
  ('2025-26', 'freshman', 'Green', 'Cedar Park High School',    NULL, '2025-08-16 10:00 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, 'Scrimmage', false),
  ('2025-26', 'freshman', 'Green', 'Anderson',                  NULL, '2025-08-21 18:00 America/Chicago', 'House Park',        NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Weiss High School',         NULL, '2025-08-27 18:30 America/Chicago', 'Weiss HS',          NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Lake Belton High School',   NULL, '2025-09-03 18:30 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Westwood High School',      NULL, '2025-09-11 18:30 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Round Rock High School',    NULL, '2025-09-18 18:30 America/Chicago', 'Round Rock HS',     NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Stony Point High School',   NULL, '2025-09-25 18:30 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Vandegrift High School',    NULL, '2025-10-02 18:30 America/Chicago', 'Vandegrift HS',     NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Vista Ridge High School',   NULL, '2025-10-09 18:30 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Cedar Ridge High School',   NULL, '2025-10-23 18:30 America/Chicago', 'Cedar Ridge HS',    NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Manor High School',         NULL, '2025-10-30 18:30 America/Chicago', 'Maverick Stadium',  NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2025-26', 'freshman', 'Green', 'Hutto High School',         NULL, '2025-11-06 18:30 America/Chicago', 'Hutto HS',          NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false);

COMMIT;

-- ===
-- db/migrations/033_seed_2025_freshman_uncolored_players.sql
-- ===

-- Migration 033: Add the 8 freshman players that had no Green/Blue
-- color fill in the source PDF, after coach clarification from Jeremy.
--
-- Assignment (per Jeremy 2026-05-17):
--   Green: #4 Conan Shin, #71 Jaxon Pelosi, #73 Favor Omagbon  (+3 -> 22 total)
--   Blue:  #19 Lamonte Brown, #53 Augustus Cocke, #55 Jaye Solages,
--          #63 Mark Llamas, #72 Brennan McCallister             (+5 -> 27 total)
--
-- Total freshman seeded across Green + Blue: 49 (matches the named
-- count from docs/2025 McNeil Football Rosters - Freshmen.pdf).
--
-- sort_order values are picked to TIE with the preceding existing
-- player on the roster, so the PlayerTable component's secondary
-- jersey-ascending sort drops each new player into the right slot
-- without requiring an UPDATE of existing rows.
--
-- Still skipped: the corrupt PDF row with no jersey# and no name
-- (position WR/LB, grade 9 only). Tracked in followups.md.

BEGIN;

-- Freshman Green additions (3).
INSERT INTO players (
  roster_id, jersey_number, first_name, last_name,
  position, grade, height, weight, sort_order, active
)
SELECT
  r.id, v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, NULL, NULL::int, v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('4',  'Conan',  'Shin',    'RB/DB', 'Fr.',  2),   -- between #2 Carter (sort 2) and #5 Brito (sort 3)
  ('71', 'Jaxon',  'Pelosi',  'OL/DL', 'Fr.', 16),   -- between #67 Cox (sort 16) and #75 Lewis (sort 17)
  ('73', 'Favor',  'Omagbon', 'OL/DL', 'Fr.', 16)    -- between #71 Pelosi (sort 16) and #75 Lewis (sort 17)
) AS v(jersey_number, first_name, last_name, position, grade, sort_order)
WHERE r.year = '2025-26'
  AND r.team_level = 'freshman'
  AND r.team_designation = 'Green'
  AND r.active = true;

-- Freshman Blue additions (5).
INSERT INTO players (
  roster_id, jersey_number, first_name, last_name,
  position, grade, height, weight, sort_order, active
)
SELECT
  r.id, v.jersey_number, v.first_name, v.last_name,
  v.position, v.grade, NULL, NULL::int, v.sort_order, true
FROM rosters r
CROSS JOIN (VALUES
  ('19', 'Lamonte',  'Brown',        'WR/DB', 'Fr.',  4),   -- between #18 James (sort 4) and #21 Smith (sort 5)
  ('53', 'Augustus', 'Cocke',        'OL/DL', 'Fr.', 16),   -- between #51 J. Harris (sort 16) and #54 Bowles (sort 17)
  ('55', 'Jaye',     'Solages',      'OL/DL', 'Fr.', 17),   -- between #54 Bowles (sort 17) and #60 Arias-Faulkner (sort 18)
  ('63', 'Mark',     'Llamas',       'OL/LB', 'Fr.', 19),   -- between #61 Boston (sort 19) and #77 Frazier (sort 20)
  ('72', 'Brennan',  'McCallister',  'OL/DL', 'Fr.', 19)    -- between #61 Boston (sort 19) and #77 Frazier (sort 20)
) AS v(jersey_number, first_name, last_name, position, grade, sort_order)
WHERE r.year = '2025-26'
  AND r.team_level = 'freshman'
  AND r.team_designation = 'Blue'
  AND r.active = true;

COMMIT;

-- ===
-- db/migrations/034_membership_tiers_pdf_reseed.sql
-- ===

-- Migration 034: Reseed membership_tiers for 2026-27 to match the
-- board-ratified PDF (docs/2026 - 2027 Membership - McNeil HS Football
-- Boosters.pdf). The seed in migration 010 predates the PDF and has
-- only 6 tiers with placeholder copy; this replaces it with the 7
-- canonical tiers.
--
-- Spec: docs/specs/boosters_join_spec.md (Slice 1 / Turn 1).
-- Filename note: spec said "030" but 030 is taken by the year-split
-- migration. This is 034 (next free slot).
--
-- DELETE (not TRUNCATE) so any rows from other years are preserved.
-- year stays '2026-27' to match the PDF + current_board_year; the
-- /boosters/join page query in Turn 2 must read current_board_year
-- (not current_year, which now governs football data).

BEGIN;

DELETE FROM membership_tiers WHERE year = '2026-27';

INSERT INTO membership_tiers
  (name, price_cents, description, perks, sort_order, year, requires_tshirt_size, requires_second_tshirt_size, badge_label, active)
VALUES
  ('Free Fan Base!', 0, 'Join Mav Nation.',
   '["Receive the Mavs Football Booster newsletter and important Mavs updates!"]'::jsonb,
   1, '2026-27', false, false, null, true),
  ('Game Day!', 2000, 'Friday nights, Mavs colors.',
   '["Mavs Football Car Decal"]'::jsonb,
   2, '2026-27', false, false, 'Most Popular', true),
  ('Offense ⇄ Defense!', 5000, 'Back both sides of the ball.',
   '["1 Mavs Football Game Day Fan or Bell", "1 Exclusive Booster Car Decal"]'::jsonb,
   3, '2026-27', false, false, null, true),
  ('Blitz!', 10000, 'Bring the pressure.',
   '["1 Exclusive Booster T-Shirt Voucher", "2 Mavs Football Car Decals"]'::jsonb,
   4, '2026-27', true, false, 'Best Value', true),
  ('Touchdown!', 25000, 'Six points for the program.',
   '["2 Exclusive Booster T-Shirt Vouchers", "2 Exclusive Booster Car Decals"]'::jsonb,
   5, '2026-27', true, true, 'Recommended', true),
  ('Playoffs!', 50000, 'Push deep into November.',
   '["2 Exclusive Booster T-Shirt Vouchers", "2 Exclusive Booster Car Decals", "Sponsorship Announcement at Home Games"]'::jsonb,
   6, '2026-27', true, true, null, true),
  ('Championship!', 100000, 'Go all in for the ring.',
   '["2 Exclusive Booster T-Shirt Vouchers", "2 Exclusive Booster Car Decals", "Sponsorship Announcement at Home Games", "Premier Parking Space at All Home Games"]'::jsonb,
   7, '2026-27', true, true, null, true);

COMMIT;

-- ===
-- db/migrations/035_fix_rrisd_athletic_forms_url.sql
-- ===

-- Migration 035: Fix RRISD Athletic Forms URL.
--
-- The /resources page card pointed to https://roundrockisd.org/athletics
-- (a landing page that requires further clicks). Jeremy 2026-05-19: the
-- direct deep link is the Rank One forms portal. Update the resource_links
-- row in place.
--
-- Idempotent: UPDATE matches on label, sets the URL. No-op on re-run.

BEGIN;

UPDATE resource_links
SET url = 'https://roundrockisd.rankone.com/New/NewInstructionsPage.aspx'
WHERE label = 'RRISD Athletic Forms';

COMMIT;

-- ===
-- db/migrations/036_hero_carousel.sql
-- ===

-- Migration 036: Homepage hero carousel — background images + foreground tiles.
-- Spec: docs/specs/commit_homepage_hero_carousel_spec.md (2026-05-19).
-- Spec calls this 035; renumbered to 036 because 035_fix_rrisd_athletic_forms_url.sql shipped first.
-- Seeds three headline_cta foreground tiles. Background images come in a follow-up migration
-- once Jeremy provides the photo count and alt text.

-- -----------------------------------------------------------------------------
-- hero_background_images: photos that rotate behind everything in the homepage hero
-- -----------------------------------------------------------------------------
CREATE TABLE hero_background_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  storage_path text NOT NULL,         -- e.g. 'hero/hero-01.jpg' inside the site-images bucket
  alt_text text NOT NULL,             -- accessibility; describe the photo
  sort_order int NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX hero_background_images_active_sort_idx
  ON hero_background_images (active, sort_order);

-- -----------------------------------------------------------------------------
-- hero_foreground_tiles: rotating content tiles overlaying the photos.
-- tile_type drives rendering; payload is jsonb for flexibility (see spec for shapes).
-- -----------------------------------------------------------------------------
CREATE TYPE hero_tile_type AS ENUM ('headline_cta', 'sponsor_spotlight');

CREATE TABLE hero_foreground_tiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tile_type hero_tile_type NOT NULL,
  payload jsonb NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX hero_foreground_tiles_active_sort_idx
  ON hero_foreground_tiles (active, sort_order);

-- -----------------------------------------------------------------------------
-- updated_at triggers (reuses touch_updated_at() from migration 006)
-- -----------------------------------------------------------------------------
CREATE TRIGGER touch_hero_background_images BEFORE UPDATE ON hero_background_images
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TRIGGER touch_hero_foreground_tiles BEFORE UPDATE ON hero_foreground_tiles
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- -----------------------------------------------------------------------------
-- RLS: public read of active rows. Admin write policies arrive with admin CRUD.
-- -----------------------------------------------------------------------------
ALTER TABLE hero_background_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE hero_foreground_tiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone reads active hero backgrounds" ON hero_background_images
  FOR SELECT TO anon, authenticated
  USING (active = true);

CREATE POLICY "Anyone reads active hero tiles" ON hero_foreground_tiles
  FOR SELECT TO anon, authenticated
  USING (active = true);

-- -----------------------------------------------------------------------------
-- Seed: three headline_cta foreground tiles per spec.
-- Background images deliberately NOT seeded here.
-- sponsor_spotlight tiles wait for SE Tier 1 sponsor capture (followups.md).
-- -----------------------------------------------------------------------------
INSERT INTO hero_foreground_tiles (tile_type, payload, sort_order) VALUES
  ('headline_cta',
   jsonb_build_object(
     'headline',  'McNeil Mavericks Football',
     'subhead',   'Home of the McNeil Mavericks, Austin, TX',
     'cta_label', 'Join the Booster Club',
     'cta_url',   '/boosters/join'
   ),
   1),
  ('headline_cta',
   jsonb_build_object(
     'headline',  'Support the Mavs',
     'subhead',   'Your booster dues fund equipment, meals, and senior gifts.',
     'cta_label', 'Make a Donation',
     'cta_url',   '/boosters/donate'
   ),
   2),
  ('headline_cta',
   jsonb_build_object(
     'headline',  'Get Involved',
     'subhead',   'Game-day help, banquet planning, sponsor outreach. We need you.',
     'cta_label', 'Volunteer',
     'cta_url',   '/boosters/volunteer'
   ),
   3);

-- ===
-- db/migrations/037_seed_hero_backgrounds.sql
-- ===

-- Migration 037: Seed six hero_background_images rows for the homepage carousel.
-- Follow-up to migration 036 (which created the table empty).
-- Source photos: docs/Backgrounds/resized/hero-0{1..6}.jpg, uploaded to the
-- site-images bucket under hero/.

INSERT INTO hero_background_images (storage_path, alt_text, sort_order, active)
VALUES
  ('hero/hero-01.jpg', 'McNeil High School marching band performing at a football game', 1, true),
  ('hero/hero-02.jpg', 'McNeil Mavericks mascot at a football game',                       2, true),
  ('hero/hero-03.jpg', 'McNeil cheer team performing during a football game',              3, true),
  ('hero/hero-04.jpg', 'McNeil cheerleaders on the sideline during a football game',       4, true),
  ('hero/hero-05.jpg', 'McNeil Mavericks player catching a touchdown pass',                5, true),
  ('hero/hero-06.jpg', 'McNeil Mavericks football team running onto the field',            6, true);

-- ===
-- db/migrations/038_print_view_pdfs.sql
-- ===

-- Migration 038: Print View PDF wiring — bucket config + schema columns + 2025-26 seed.
-- Spec: docs/specs/commit_print_view_pdfs_spec.md (2026-05-19).
--
-- Conflicts with spec, resolved per "default to your reading" guidance:
--   * Spec assumed `team_levels` table exists; it does NOT. `team_level` is an ENUM
--     ('varsity','jv','freshman') and per-team-per-year metadata lives on `rosters`
--     (one row per (year, team_level, team_designation)).
--   * Spec assumed `freshman_green` / `freshman_blue` enum values; freshman color
--     split is actually in `rosters.team_designation` (text: 'Green' or 'Blue').
--   * `documents` bucket already exists (created in or before migration 009, which
--     also pre-baked the RLS read/write policies for it). Bucket needs UPDATE for
--     size + MIME constraints, not INSERT.
--
-- Resolution: add BOTH pdf_storage_path AND schedule_pdf_storage_path to `rosters`.
-- That table is already the per-team-per-year anchor at the cardinality the spec
-- wants for per-team schedule PDFs (Option B — "per-team schedule PDFs from day
-- one"). Schedule pages will look up the matching rosters row for their PDF path.

-- -----------------------------------------------------------------------------
-- documents bucket config (bucket already exists; tighten constraints)
-- -----------------------------------------------------------------------------
UPDATE storage.buckets
SET file_size_limit = 5242880,
    allowed_mime_types = ARRAY['application/pdf']
WHERE id = 'documents';

-- Public read policy on storage.objects for 'documents' was provisioned by
-- migration 009 ("Anyone reads public buckets"). No new policy needed here.

-- -----------------------------------------------------------------------------
-- Schema: PDF path columns on rosters
-- -----------------------------------------------------------------------------
ALTER TABLE rosters ADD COLUMN pdf_storage_path text;
ALTER TABLE rosters ADD COLUMN schedule_pdf_storage_path text;

-- -----------------------------------------------------------------------------
-- Seed: 2025-26 PDF paths
-- -----------------------------------------------------------------------------

-- Varsity + JV — one row each, team_designation IS NULL.
UPDATE rosters SET pdf_storage_path = 'documents/rosters/varsity-2025.pdf'
  WHERE year = '2025-26' AND team_level = 'varsity';

UPDATE rosters SET pdf_storage_path = 'documents/rosters/jv-2025.pdf'
  WHERE year = '2025-26' AND team_level = 'jv';

-- Freshman — both Green and Blue rows get the same path for 2025-26 (per spec).
-- Filter on team_level alone catches both team_designation rows.
UPDATE rosters SET pdf_storage_path = 'documents/rosters/freshman-2025.pdf'
  WHERE year = '2025-26' AND team_level = 'freshman';

-- Schedule PDF — all four 2025-26 rosters get the same path. Diverge later by
-- UPDATEing individual (team_level, team_designation) rows.
UPDATE rosters SET schedule_pdf_storage_path = 'documents/schedules/2025-26.pdf'
  WHERE year = '2025-26';

-- ===
-- db/migrations/039_update_coach_wallin.sql
-- ===

-- Migration 039: Update Coach Wallin's name + role.
-- Spec: docs/specs/commit_print_view_pdfs_spec.md Part 2 (2026-05-19).
--
-- Pre-migration state (confirmed via SELECT before applying):
--   name           = 'Coach Wallin'
--   role           = 'Position Coach'
--   role_category  = 'position_coach'
--
-- Spec wording note: spec says "position" but the column is `role`. Updating `role`.
-- Head-coach check: role_category is 'position_coach', not 'head' — no slot clearing
-- needed. Wallin stays in the Position Coaches section.

UPDATE coaches
SET name = 'Douglas Wallin',
    role = 'Defensive Line Coach'
WHERE id = 'a4e36da9-6371-4400-a9c7-dbed6ddce0fa';

-- ===
-- db/migrations/040_fix_freshmen_pdf_path.sql
-- ===

-- Migration 040: Fix freshman roster PDF path to use 'freshmen' (plural).
-- Migration 038 seeded 'freshman-2025.pdf' (singular, matching the team_level enum),
-- but the uploaded file in Storage is 'freshmen-2025.pdf' (plural, matching the
-- source PDF filename). Per Jeremy's preference, the storage filename stays plural.

UPDATE rosters
SET pdf_storage_path = 'documents/rosters/freshmen-2025.pdf'
WHERE year = '2025-26' AND team_level = 'freshman';

-- ===
-- db/migrations/041_sponsors_seed.sql
-- ===

-- 041_sponsors_seed.sql
-- Seed 2025-26 sponsors (7 rows: 1 MVP placeholder + 6 last-year Golds),
-- 1 "Become a Sponsor" headline_cta hero tile, and 3 sponsor_spotlight hero
-- tiles for the featured sponsors. Per
-- docs/specs/commit_sponsors_seed_and_carousel_spec_v2.md.
--
-- Note on tier year: migration 030's year split relabeled rosters/practice/
-- coaches/games from 2026-27 to 2025-26 to match site_settings.current_year,
-- but missed sponsorship_tiers. Per content_map_v2.md the /sponsors and
-- homepage sponsor queries read by current_year, so this migration also
-- relabels the sponsorship_tiers rows from 2026-27 to 2025-26 before
-- inserting sponsors (otherwise the tier_id lookups below would be NULL).

begin;

-- Pre-step: relabel sponsorship_tiers year to match current_year (2025-26).
update sponsorship_tiers
  set year = '2025-26'
  where year = '2026-27';

-- Sponsors (uses tier IDs by name).
do $$
declare
  mvp_tier uuid;
  gold_tier uuid;
begin
  select id into mvp_tier from sponsorship_tiers where year = '2025-26' and name = 'MVP';
  select id into gold_tier from sponsorship_tiers where year = '2025-26' and name = 'Gold';

  if mvp_tier is null then
    raise exception 'MVP tier not found for year 2025-26';
  end if;
  if gold_tier is null then
    raise exception 'Gold tier not found for year 2025-26';
  end if;

  insert into sponsors (name, logo_url, website_url, tier_id, year, featured, sort_order, active) values
    ('Rudy''s BBQ',
     'rudys-bbq.png',
     'https://rudysbbq.com',
     mvp_tier, '2025-26', true, 1, true),
    ('AutoNation Chevrolet West Austin',
     'autonation-chevrolet-west-austin.png',
     'https://www.autonationchevroletwestaustin.com',
     gold_tier, '2025-26', true, 2, true),
    ('Sunflower Bank',
     'sunflower-bank.png',
     'https://www.sunflowerbank.com',
     gold_tier, '2025-26', true, 3, true),
    ('LUV Braces',
     'luv-braces.png',
     'https://luvbraces.com',
     gold_tier, '2025-26', false, 4, true),
    ('Dave''s Ultimate Automotive',
     'daves-ultimate-automotive.png',
     'https://davesultimateautomotive.com',
     gold_tier, '2025-26', false, 5, true),
    ('TKO Heating and Air',
     'tko-heating-and-air.png',
     'https://www.tkomechanical.com',
     gold_tier, '2025-26', false, 6, true),
    ('Laurie Flood, Realtor',
     'laurie-flood-realtor.png',
     'https://austintexasbestrealestate.com',
     gold_tier, '2025-26', false, 7, true);
end $$;

-- New "Become a Sponsor" headline_cta tile (Pool A → 4 tiles).
insert into hero_foreground_tiles (tile_type, payload, sort_order, active) values
  ('headline_cta',
   '{"headline":"Become a Sponsor","subhead":"Five tiers, real visibility. Reach every Mavs family from August through December.","cta_label":"Sponsorship Info","cta_url":"/boosters/sponsor"}'::jsonb,
   4, true);

-- Sponsor spotlight tiles for the 3 featured sponsors (Pool B).
insert into hero_foreground_tiles (tile_type, payload, sort_order, active) values
  ('sponsor_spotlight',
   '{"sponsor_name":"Rudy''s BBQ","logo_bucket":"sponsor-logos","logo_storage_path":"rudys-bbq.png","tagline":null,"website_url":"https://rudysbbq.com"}'::jsonb,
   101, true),
  ('sponsor_spotlight',
   '{"sponsor_name":"AutoNation Chevrolet West Austin","logo_bucket":"sponsor-logos","logo_storage_path":"autonation-chevrolet-west-austin.png","tagline":null,"website_url":"https://www.autonationchevroletwestaustin.com"}'::jsonb,
   102, true),
  ('sponsor_spotlight',
   '{"sponsor_name":"Sunflower Bank","logo_bucket":"sponsor-logos","logo_storage_path":"sunflower-bank.png","tagline":null,"website_url":"https://www.sunflowerbank.com"}'::jsonb,
   103, true);

commit;

-- ===
-- db/migrations/042_hero_bg_reorder.sql
-- ===

-- 042_hero_bg_reorder.sql
-- Swap sort_order between hero-01.jpg (band) and hero-06.jpg (football team
-- running onto the field) so the carousel opens with the team-running image
-- instead of the band. Band moves to the last slot in the rotation; cycle
-- length unchanged.

begin;

update hero_background_images set sort_order = 99 where storage_path = 'hero/hero-06.jpg';
update hero_background_images set sort_order = 6  where storage_path = 'hero/hero-01.jpg';
update hero_background_images set sort_order = 1  where storage_path = 'hero/hero-06.jpg';

commit;

-- ===
-- db/migrations/043_remove_sponsor_spotlight_tiles.sql
-- ===

-- 043_remove_sponsor_spotlight_tiles.sql
-- Remove the 3 sponsor_spotlight hero tiles seeded by migration 041
-- (Rudy's, AutoNation, Sunflower). Jeremy doesn't want sponsor logos
-- rotating in the carousel — the homepage sponsors strip + /sponsors
-- page already cover that. The HeroCarousel two-pool rotation falls
-- back to single-pool CTA-only when sponsorTiles is empty, so this is
-- a DB-only change.

begin;

delete from hero_foreground_tiles
  where tile_type = 'sponsor_spotlight'
  and payload->>'sponsor_name' in (
    'Rudy''s BBQ',
    'AutoNation Chevrolet West Austin',
    'Sunflower Bank'
  );

commit;

-- ===
-- db/migrations/044_reset_sponsors_featured.sql
-- ===

-- 044_reset_sponsors_featured.sql
-- Reset sponsors.featured to false for all 2025-26 rows. The featured flag
-- was originally used by the hero carousel sponsor_spotlight tiles to pick
-- which sponsors got airtime; those tiles were removed in migration 043.
-- The homepage strip now partitions by tier name (MVP vs non-MVP) instead of
-- the featured flag. The column stays in the schema for future use cases
-- (e.g. "featured sponsor of the month" or admin-driven badging).
--
-- Pre-check: grep across app/, lib/, components/ confirmed no live code path
-- reads sponsors.featured at the time this migration was written.

begin;

update sponsors
  set featured = false
  where year = '2025-26';

commit;

-- ===
-- db/migrations/045_committees_full_descriptions.sql
-- ===

-- 045_committees_full_descriptions.sql
-- Update committees with full SE-site descriptions per spec_review.md.
-- Original seed (migration 010) used abbreviated copy; this replaces with
-- the verbatim descriptions from the existing SportsEngine site so the new
-- /boosters/committees page can show recruiting-grade detail per committee.
--
-- Renumbered from spec's 044 because 044 is already taken by
-- 044_reset_sponsors_featured.sql (shipped 2026-05-22).

begin;

update committees set description = 'Maintain football website for communications and notification to parents and players. Maintain Facebook and Twitter accounts. Ongoing throughout school year.' where name = 'Social Media';

update committees set description = 'Coordinate pregame meals for freshman and JV. Discuss menu and price with Sponsor. Identify vendors, solicit bids, coordinate pickup and delivery. Coordinate Varsity parent team dinners. Football season only.' where name = 'Team Meals';

update committees set description = 'Maintain membership list (emails, contact info, current player roster). Collect sign-in sheets from meetings and events. Promote the Booster Club. Ongoing.' where name = 'Membership';

update committees set description = 'Vendors, pricing, design, purchase, inventory. Schedule volunteers to sell at events. Monthly report at Booster meeting. Work with Social Media to advertise. Ongoing.' where name = 'Merchandise';

update committees set description = 'Date, location, volunteers for spring and fall parent meetings. Work with Social Media, Merchandise, and Membership committees. Two-time activity.' where name = 'Parent Meetings';

update committees set description = 'Date, time schedule. Cafeteria booking. Vendor bids. Awards coordination with Sponsor. Volunteer coordination for ads, tickets, decorations, senior gifts. One-time activity.' where name = 'Football Banquet';

update committees set description = 'Pool location, volunteers, food donations. Advertise via Social Media. One-time activity.' where name = 'Summer Events';

update committees set description = 'Date with Sponsor and Principal. Coordinate with other booster clubs. Food vendor bids. Tables, volunteers. One-time activity.' where name = 'Meet the Mavs';

update committees set description = 'Game date set by RRISD. Senior names from Sponsor. Permissions, flower vendors, volunteers. One-time activity.' where name = 'Senior Night';

update committees set description = 'Event date. Business sponsorships. Advertise via Social Media. Application and payment design. Spirit wear order. Volunteers. One-time activity.' where name = 'Tunnel Stampede';

update committees set description = 'Oversee any board-determined fundraisers. Coordinate with Social Media. Ongoing.' where name = 'Fundraisers';

commit;

-- ===
-- db/migrations/046_resources_add_news_and_mavmail.sql
-- ===

-- 046_resources_add_news_and_mavmail.sql
--
-- Adds two entries to the resource_links 'communications' section so that
-- /news (now removed from top-level nav) and the weekly MavMail newsletter
-- are discoverable from the Forms & Links page (/resources).
--
-- The 'communications' section enum value stays as-is at the DB level; only
-- the UI heading rendered in app/resources/page.tsx flips to "News and
-- Communications" (hardcoded SECTION_ORDER, no schema change needed).
--
-- sort_order strategy: existing siblings are HUDL=1, SportsYou=2. New rows
-- use negative sort_order so they render first (ORDER BY ASC) WITHOUT
-- renumbering existing rows. MavMail=-2 (top), /news=-1 (second).

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
VALUES
  ('communications', 'MavMail', 'https://roundrockisd.edurooms.com/newsletters/mcneil-high-school/newsletters/mavmail-sunday-may-24-2026', NULL, 'mail', -2, true),
  ('communications', 'News', '/news', 'McNeil Mavericks football news and updates.', 'newspaper', -1, true);

COMMIT;

-- ===
-- db/migrations/047_resources_drop_news_add_mavmail_description.sql
-- ===

-- 047_resources_drop_news_add_mavmail_description.sql
--
-- Two changes in 'communications' section of resource_links:
--   1. Drop the standalone "News" entry added in 046. There is no /news
--      route planned; the link would 404.
--   2. Add a description to the MavMail row (was NULL in 046).
--
-- The "News & Communications" UI heading rename landed in code in
-- commit f11c5f4 + same-commit fix for "&" vs "and" consistency with
-- the other section headings (app/resources/page.tsx SECTION_ORDER);
-- no DB change needed for that.

BEGIN;

DELETE FROM resource_links
WHERE section = 'communications'
  AND label = 'News'
  AND url = '/news';

UPDATE resource_links
SET description = 'McNeil High School''s weekly newsletter. Published most Sundays at 5PM.'
WHERE label = 'MavMail'
  AND section = 'communications';

COMMIT;

-- ===
-- db/migrations/048_events_seed.sql
-- ===

-- 048_events_seed.sql
--
-- Seeds 3 initial events for the new /events page (events_page_spec.md).
-- One upcoming (Parent and Athlete Meeting on 2026-05-26) and two past
-- (2025 Football Banquet, 2025 Meet the Mavs) so the Upcoming/Past
-- filter pills demo with real data.
--
-- Time-zone offsets are explicit: -05 for Central Daylight (CDT), -06
-- for Central Standard (CST). The August 2025 and May 2026 dates fall
-- inside CDT; the December 2025 banquet falls inside CST.

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
) VALUES
(
  'Parent and Athlete Meeting',
  'parent-athlete-meeting-may-2026',
  'Important meeting for parents and athletes covering the 2026-27 season. Topics include summer workouts, fall expectations, and key dates for the upcoming season. Please make every effort to attend.',
  '2026-05-26 19:00:00-05'::timestamptz,
  '2026-05-26 20:30:00-05'::timestamptz,
  'McNeil High School Cafeteria',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  '2025 Football Banquet',
  'football-banquet-2025',
  'End-of-season celebration honoring the 2025 McNeil Mavericks varsity, JV, and freshman football teams. Awards, video highlights, and dinner.',
  '2025-12-06 18:00:00-06'::timestamptz,
  '2025-12-06 21:00:00-06'::timestamptz,
  'McNeil High School Cafeteria',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  '2025 Meet the Mavs',
  'meet-the-mavs-2025',
  'Annual season-kickoff event introducing the 2025-26 Mavericks football team to the community. Player introductions, coach remarks, and food.',
  '2025-08-15 18:00:00-05'::timestamptz,
  '2025-08-15 20:00:00-05'::timestamptz,
  'McNeil High School Stadium',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
);

COMMIT;

-- ===
-- db/migrations/049_resources_add_facebook_parents_group.sql
-- ===

-- 049_resources_add_facebook_parents_group.sql
--
-- Adds one row to the resource_links 'communications' section: the
-- McNeil Mavericks Football Parents Facebook Group. Positioned at
-- sort_order=3 -- immediately below SportsYou (2). No renumbering of
-- existing rows needed; sort_order=3 was unused.
--
-- NOTE on naming: the table is resource_links (not resources) and the
-- column is section (an ENUM, not category). The DB enum value
-- 'communications' is unchanged; the UI heading "News & Communications"
-- is rendered by app/resources/page.tsx SECTION_ORDER.
--
-- icon_hint='facebook' is a new lowercase hint registered in
-- lib/resource-icons.tsx (inline SVG, since lucide-react v1.x dropped
-- brand glyphs for trademark reasons -- same pattern as Footer.tsx).

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
VALUES (
  'communications',
  'McNeil Mavericks Football Parents (Facebook Group)',
  'https://www.facebook.com/groups/967201656648938',
  'This group is for parents of ALL McNeil High School football athletes to share information.',
  'facebook',
  3,
  true
);

COMMIT;

-- ===
-- db/migrations/050_events_fix_parent_meeting_time.sql
-- ===

-- 050_events_fix_parent_meeting_time.sql
--
-- Migration 048 seeded the Parent and Athlete Meeting at 7:00 PM CDT
-- (19:00). Actual start time is 6:30 PM CDT. End time stays at 8:30 PM
-- CDT (the meeting now runs 2 hours instead of the original 1.5).

BEGIN;

UPDATE events
SET starts_at = '2026-05-26 18:30:00-05'::timestamptz
WHERE slug = 'parent-athlete-meeting-may-2026';

COMMIT;

-- ===
-- db/migrations/051_resources_add_game_photos_clear_bag_mhs.sql
-- ===

-- 051_resources_add_game_photos_clear_bag_mhs.sql
--
-- Adds three resource_links rows:
--   1. Game Photos (communications, sort_order=4) — family-sourced photo
--      doc; sibling to the Facebook Parents Group above it. New icon_hint
--      'photo' (registered in lib/resource-icons.tsx with a lucide Camera).
--   2. Clear Bag Policy (stadiums, sort_order=2) — RRISD district policy,
--      placed directly after Kelly Reeves Athletic Complex.
--   3. McNeil High School (resources, sort_order=1) — institutional link,
--      first entry in the Resources section (previously empty).

BEGIN;

INSERT INTO resource_links (section, sort_order, label, description, url, icon_hint, active)
VALUES
  (
    'communications',
    4,
    'Game Photos',
    'Game photos shared by McNeil Mavericks families.',
    'https://docs.google.com/document/d/1fh_49R9mn_8QXgjAAr1DmWlmnLHH3dVyjlPjLv1JaZ0/edit?tab=t.0#heading=h.gf4l39u0yuz6',
    'photo',
    true
  ),
  (
    'stadiums',
    2,
    'Clear Bag Policy',
    'Round Rock ISD clear bag requirements for athletic events.',
    'https://www.roundrockisd.org/page/clear-bag-policy',
    'external',
    true
  ),
  (
    'resources',
    1,
    'McNeil High School',
    'Official school website.',
    'https://mcneil.roundrockisd.org/',
    'external',
    true
  );

COMMIT;

-- ===
-- db/migrations/052_resources_and_games_backfill.sql
-- ===

-- 052_resources_and_games_backfill.sql
--
-- 1. Move HUDL from News & Communications to Resources.
-- 2. Rename Kelly Reeves Athletic Complex → "Kelly Reeves Athletic Complex (KRAC)".
-- 3. Remove the Clear Bag Policy resource row; the /resources page now
--    renders it as a small subordinate link below the Stadiums list
--    (hardcoded against CLEAR_BAG_POLICY_URL in lib/constants.ts).
-- 4. Add House Park + Dragon Stadium stadium rows (addresses verified
--    via Round Rock ISD, Austin ISD, and TexasBob.com).
-- 5. Backfill 2025-26 varsity scores from MaxPreps (9 wins/losses on
--    finalized games; Hutto stays result_status='scheduled' with a
--    watch_url so the Result cell renders "Watch →" instead of em-dash).
-- 6. Populate games.location_url for games at KRAC / House Park /
--    Dragon Stadium across every team level.

BEGIN;

-- 1. HUDL move
UPDATE resource_links
SET section = 'resources', sort_order = 2
WHERE label = 'HUDL' AND section = 'communications';

-- 2. KRAC rename
UPDATE resource_links
SET label = 'Kelly Reeves Athletic Complex (KRAC)'
WHERE label = 'Kelly Reeves Athletic Complex' AND section = 'stadiums';

-- 3. Drop the Clear Bag Policy row (rendered as a subordinate link in code)
DELETE FROM resource_links
WHERE url = 'https://www.roundrockisd.org/page/clear-bag-policy';

-- 4. New stadium rows
INSERT INTO resource_links (section, sort_order, label, description, url, icon_hint, active) VALUES
  (
    'stadiums',
    2,
    'House Park',
    '1301 Shoal Creek Blvd, Austin, TX 78701. Austin ISD stadium hosting Anderson HS home football.',
    'https://www.google.com/maps/search/?api=1&query=1301+Shoal+Creek+Blvd%2C+Austin%2C+TX+78701',
    'external',
    true
  ),
  (
    'stadiums',
    3,
    'Dragon Stadium',
    '300 N Lake Creek Dr, Round Rock, TX 78681. Home of the Round Rock Dragons.',
    'https://www.google.com/maps/search/?api=1&query=300+N+Lake+Creek+Dr%2C+Round+Rock%2C+TX+78681',
    'external',
    true
  );

-- 5. 2025-26 varsity scores backfill (chronological)
UPDATE games SET result_status='final', our_score=28, their_score=56
WHERE year='2025-26' AND team_level='varsity' AND opponent='Weiss High School';

UPDATE games SET result_status='final', our_score=34, their_score=28
WHERE year='2025-26' AND team_level='varsity' AND opponent='Lake Belton High School';

UPDATE games SET result_status='final', our_score=70, their_score=45
WHERE year='2025-26' AND team_level='varsity' AND opponent='Westwood High School';

UPDATE games SET result_status='final', our_score=17, their_score=31
WHERE year='2025-26' AND team_level='varsity' AND opponent='Round Rock High School';

UPDATE games SET result_status='final', our_score=56, their_score=21
WHERE year='2025-26' AND team_level='varsity' AND opponent='Stony Point High School';

UPDATE games SET result_status='final', our_score=17, their_score=14
WHERE year='2025-26' AND team_level='varsity' AND opponent='Vandegrift High School';

UPDATE games SET result_status='final', our_score=45, their_score=42
WHERE year='2025-26' AND team_level='varsity' AND opponent='Vista Ridge High School';

UPDATE games SET result_status='final', our_score=35, their_score=38
WHERE year='2025-26' AND team_level='varsity' AND opponent='Cedar Ridge High School';

UPDATE games SET result_status='final', our_score=42, their_score=21
WHERE year='2025-26' AND team_level='varsity' AND opponent='Manor High School';

-- Last varsity game — Hutto. Leave as scheduled with no score; set
-- watch_url so the Result cell renders "Watch →" instead of em-dash.
UPDATE games SET watch_url='https://www.youtube.com/@iHSFan'
WHERE year='2025-26' AND team_level='varsity' AND opponent='Hutto High School';

-- Aug 21 Anderson scrimmage left as result_status='scheduled' with no
-- score. SA1 research didn't surface a MaxPreps score for this game;
-- per the original seed build log (032), it appears to have been a
-- non-district season opener / scrimmage.

-- 6. location_url backfill — all team levels, all 2025-26 games at the
-- three stadiums we know about. Same URL for every game at the same
-- venue; no schema change needed (column already exists).
UPDATE games
SET location_url='https://www.google.com/maps/search/?api=1&query=10211+W+Parmer+Ln%2C+Austin%2C+TX+78717'
WHERE year='2025-26' AND location='KRAC';

UPDATE games
SET location_url='https://www.google.com/maps/search/?api=1&query=1301+Shoal+Creek+Blvd%2C+Austin%2C+TX+78701'
WHERE year='2025-26' AND location='House Park';

UPDATE games
SET location_url='https://www.google.com/maps/search/?api=1&query=300+N+Lake+Creek+Dr%2C+Round+Rock%2C+TX+78681'
WHERE year='2025-26' AND location='Dragon Stadium';

COMMIT;

-- ===
-- db/migrations/053_temporary_swap_contact_email_to_gmail.sql
-- ===

-- 053_temporary_swap_contact_email_to_gmail.sql
--
-- TEMPORARY swap of boosters@mcneilmavericks.org → mcneilfootballboosters@gmail.com
-- on every public-surface DB row, so the board's pre-admin-phase review (2026-05-26
-- meeting) doesn't see an aliased address that isn't wired up yet. The .org alias
-- will be restored via 053_rollback.sql once Cloudflare Email Routing is live.
--
-- Affected rows:
--   1. site_settings.primary_contact_email (singleton row, id=1)
--   2. resource_links SportsYou description (embedded mention of the booster email)

BEGIN;

-- 1. site_settings singleton
UPDATE site_settings
SET primary_contact_email = 'mcneilfootballboosters@gmail.com'
WHERE id = 1
  AND primary_contact_email = 'boosters@mcneilmavericks.org';

-- 2. SportsYou resource_links row description
UPDATE resource_links
SET description = REPLACE(
  description,
  'boosters@mcneilmavericks.org',
  'mcneilfootballboosters@gmail.com'
)
WHERE label = 'SportsYou (Team Messaging)'
  AND description LIKE '%boosters@mcneilmavericks.org%';

COMMIT;

-- ===
-- db/migrations/054_sponsor_tier_perk_trims.sql
-- ===

-- 054_sponsor_tier_perk_trims.sql
-- Trim sponsorship tier perks per Jeremy 2026-05-29.
--   Blue ($500):     drop "Sign at field", "Game program: Quarter page", "Streaming recognition".
--   Gold ($1000):    "Game program: Half page" -> "Game program"; drop "Streaming recognition".
--   Platinum ($1500): drop "Streaming banner all games".
-- Diamond + MVP untouched (streaming banner remains only on those two tiers).
-- Full-array replacement scoped by name + year so re-running is idempotent.

begin;

update sponsorship_tiers
set perks = '["Logo + link on website", "Social + newsletter promo", "PA announcement"]'::jsonb
where name = 'Blue' and year = '2025-26';

update sponsorship_tiers
set perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program"]'::jsonb
where name = 'Gold' and year = '2025-26';

update sponsorship_tiers
set perks = '["Logo + link on website", "Sign at field", "Social + newsletter promo", "PA announcement", "Game program: Full page", "2x 30-sec audio commercials per game"]'::jsonb
where name = 'Platinum' and year = '2025-26';

commit;

-- ===
-- db/migrations/055_coaches_year_split_and_gardner.sql
-- ===

-- Migration 055: Decouple the coaches display year from current_year, advance it
-- to 2026-27, and seed Jerry Gardner as Head Coach and Athletic Director.
--
-- Why a new year field: current_year governs ALL football data (rosters,
-- players, practice_schedules, games, coaches). The new head coach was named
-- 2026-06-03 and Jeremy wants the /coaches page to show the 2026-27 staff NOW,
-- while rosters/schedule/games stay on the completed 2025-26 season. Mirrors the
-- existing current_board_year decoupling from migration 030.
--
-- Changes (single transaction):
--   1. Add site_settings.current_coaches_year (default '2026-27'); coaches page
--      will read this instead of current_year.
--   2. Re-stamp the two existing coaches (Hale, Wallin) 2025-26 -> 2026-27 so
--      they keep showing under the now-2026-27 coaches page.
--   3. Insert Jerry Gardner (role_category 'head') at 2026-27 with his photo.
--
-- Idempotent: column add is IF NOT EXISTS; the year re-stamp filters by old
-- value; the Gardner insert guards on NOT EXISTS. Reversible via 055_rollback.sql.

BEGIN;

ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS current_coaches_year text NOT NULL DEFAULT '2026-27';

UPDATE site_settings SET current_coaches_year = '2026-27' WHERE id = 1;

UPDATE coaches SET year = '2026-27' WHERE year = '2025-26';

INSERT INTO coaches (year, name, role, role_category, photo_url, bio, sort_order, active)
SELECT
  '2026-27',
  'Jerry Gardner',
  'Head Coach and Athletic Director',
  'head',
  'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/JerryGardner.png',
  'Jerry Gardner joins McNeil as head football coach in 2026. He comes from Wylie East, where he served as offensive coordinator and quarterbacks coach and helped lead the program to consecutive 10-win seasons. He previously was head coach at Glenpool High School in Oklahoma and coached in Plano ISD. A native of Lone Grove, Oklahoma, Gardner played college football at the University of Central Oklahoma.',
  1,
  true
WHERE NOT EXISTS (
  SELECT 1 FROM coaches WHERE year = '2026-27' AND role_category = 'head'
);

COMMIT;

-- ===
-- db/migrations/056_add_current_schedule_year.sql
-- ===

-- Migration 056: decouple the displayed SCHEDULE year from current_year.
-- Same pattern as current_board_year (030) and current_coaches_year (055).
-- Default '2025-26' so NOTHING changes on deploy; migration 058 flips it to
-- '2026-27' as the single go-live switch. Rosters/practice/sponsors/tiers stay
-- on current_year='2025-26' and are unaffected.
BEGIN;
ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS current_schedule_year text NOT NULL DEFAULT '2025-26';
UPDATE site_settings SET current_schedule_year = '2025-26' WHERE id = 1;
COMMIT;

-- ===
-- db/migrations/057_seed_2026_schedule.sql
-- ===

-- Migration 057: seed the real 2026-27 schedule (40 rows) + 2026-27 schedule-PDF
-- stub roster rows. Source: docs/Round Rock McNeil 2026 - corrected.pdf
-- (Jonathan Cruz->Jerry Gardner; Senior Night moved to V Sep 4 Lake Belton).
-- Verified: weekdays vs 2026 calendar (0 mismatches) + independent cell-by-cell
-- PDF check (CLEAN). District '*' stripped from opponent names (no column),
-- matching migration 032. Senior Night/Homecoming carried in notes.
-- Aug 13 + Aug 20 (TBD-kickoff preseason games) are intentionally OMITTED from
-- the site per Jeremy; they remain on the downloadable PDF only.
-- All games Aug-Oct 2026 = CDT; PG handles the tz literal.
--
-- Print View PDF: schedule game pages read schedule_pdf_storage_path off a
-- rosters row matched on (current_schedule_year, level, designation). Real
-- rosters live at 2025-26, so 4 stub rosters rows at 2026-27 carry ONLY the
-- schedule PDF path (no players); roster *pages* read current_year (2025-26)
-- and never see these stubs.
--
-- Cleanup when admin CRUD lands:
--   DELETE FROM games WHERE year='2026-27';
--   DELETE FROM rosters WHERE year='2026-27' AND pdf_storage_path IS NULL;

BEGIN;

INSERT INTO games (
  year, team_level, team_designation,
  opponent, opponent_url, game_date, location, location_url,
  home_or_away, result_status, our_score, their_score,
  watch_url, notes, featured
) VALUES
  -- VARSITY (10) — Aug 13/20 scrimmages omitted from site (on PDF only)
  ('2026-27', 'varsity', NULL, 'Austin Bowie High School', NULL, '2026-08-28 19:00 America/Chicago', 'Burger Stadium', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Lake Belton High School', NULL, '2026-09-04 19:00 America/Chicago', 'Dragon Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, 'Senior Night', false),
  ('2026-27', 'varsity', NULL, 'Rouse High School', NULL, '2026-09-11 19:00 America/Chicago', 'Gupton', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Vista Ridge High School', NULL, '2026-09-18 19:00 America/Chicago', 'Gupton', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Lake Travis High School', NULL, '2026-09-24 19:00 America/Chicago', 'KRAC', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Cedar Ridge High School', NULL, '2026-10-02 19:00 America/Chicago', 'KRAC', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Stony Point High School', NULL, '2026-10-09 19:00 America/Chicago', 'KRAC', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Westlake High School', NULL, '2026-10-16 19:00 America/Chicago', 'Chaparral', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'varsity', NULL, 'Round Rock High School', NULL, '2026-10-23 19:00 America/Chicago', 'KRAC', NULL, 'home', 'scheduled', NULL, NULL, NULL, 'Homecoming', false),
  ('2026-27', 'varsity', NULL, 'Westwood High School', NULL, '2026-10-30 19:00 America/Chicago', 'KRAC', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  -- JV (10)
  ('2026-27', 'jv', NULL, 'Austin Bowie High School', NULL, '2026-08-27 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Lake Belton High School', NULL, '2026-09-03 18:00 America/Chicago', 'Lake Belton HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Rouse High School', NULL, '2026-09-10 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Vista Ridge High School', NULL, '2026-09-17 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Lake Travis High School', NULL, '2026-09-23 18:00 America/Chicago', 'Lake Travis HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Cedar Ridge High School', NULL, '2026-10-01 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Stony Point High School', NULL, '2026-10-08 18:00 America/Chicago', 'Stony Point HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Westlake High School', NULL, '2026-10-15 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Round Rock High School', NULL, '2026-10-22 18:00 America/Chicago', 'Dragon Stadium', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'jv', NULL, 'Westwood High School', NULL, '2026-10-29 18:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  -- FRESHMAN BLUE (10) @5:00pm
  ('2026-27', 'freshman', 'Blue', 'Austin Bowie High School', NULL, '2026-08-27 17:00 America/Chicago', 'Bowie HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Lake Belton High School', NULL, '2026-09-03 17:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Rouse High School', NULL, '2026-09-10 17:00 America/Chicago', 'Rouse HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Vista Ridge High School', NULL, '2026-09-17 17:00 America/Chicago', 'Vista Ridge HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Lake Travis High School', NULL, '2026-09-23 17:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Cedar Ridge High School', NULL, '2026-10-01 17:00 America/Chicago', 'Cedar Ridge HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Stony Point High School', NULL, '2026-10-08 17:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Westlake High School', NULL, '2026-10-15 17:00 America/Chicago', 'Westlake HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Round Rock High School', NULL, '2026-10-22 17:00 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Blue', 'Westwood High School', NULL, '2026-10-29 17:00 America/Chicago', 'Westwood HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  -- FRESHMAN GREEN (10) @6:30pm
  ('2026-27', 'freshman', 'Green', 'Austin Bowie High School', NULL, '2026-08-27 18:30 America/Chicago', 'Bowie HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Lake Belton High School', NULL, '2026-09-03 18:30 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Rouse High School', NULL, '2026-09-10 18:30 America/Chicago', 'Rouse HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Vista Ridge High School', NULL, '2026-09-17 18:30 America/Chicago', 'Vista Ridge HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Lake Travis High School', NULL, '2026-09-23 18:30 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Cedar Ridge High School', NULL, '2026-10-01 18:30 America/Chicago', 'Cedar Ridge HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Stony Point High School', NULL, '2026-10-08 18:30 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Westlake High School', NULL, '2026-10-15 18:30 America/Chicago', 'Westlake HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Round Rock High School', NULL, '2026-10-22 18:30 America/Chicago', 'Maverick Stadium', NULL, 'home', 'scheduled', NULL, NULL, NULL, NULL, false),
  ('2026-27', 'freshman', 'Green', 'Westwood High School', NULL, '2026-10-29 18:30 America/Chicago', 'Westwood HS', NULL, 'away', 'scheduled', NULL, NULL, NULL, NULL, false);

INSERT INTO rosters (year, team_level, team_designation, active, schedule_pdf_storage_path)
VALUES
  ('2026-27', 'varsity',  NULL,    true, 'documents/schedules/2026-27.pdf'),
  ('2026-27', 'jv',       NULL,    true, 'documents/schedules/2026-27.pdf'),
  ('2026-27', 'freshman', 'Green', true, 'documents/schedules/2026-27.pdf'),
  ('2026-27', 'freshman', 'Blue',  true, 'documents/schedules/2026-27.pdf');

COMMIT;

-- ===
-- db/migrations/058_flip_schedule_year_2026.sql
-- ===

-- Migration 058: GO-LIVE. Flip the public schedule to the 2026-27 season.
-- Pre-req: 056 applied, 057 seeded, code reads current_schedule_year, and the
-- corrected PDF uploaded to documents bucket at schedules/2026-27.pdf.
-- Reversible: 058_rollback.sql sets it back to 2025-26.
BEGIN;
UPDATE site_settings SET current_schedule_year = '2026-27' WHERE id = 1;
COMMIT;

-- ===
-- db/migrations/059_events_seed_pool_party_2026.sql
-- ===

-- 059_events_seed_pool_party_2026.sql
--
-- Seeds the 2026 Mavs Football Pool Party as a published upcoming event
-- on /events (events_page_spec.md). Same column set and CDT offset
-- convention as 048_events_seed.sql.
--
-- Aug 7, 2026 falls inside Central Daylight Time, so the offset is -05.
-- Location is Pearson Place Pavilion at the Avery Ranch community pool
-- (10000 Ivalenes Hope Dr, Austin, TX 78717), per the 2025 flyer.

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
) VALUES
(
  'McNeil Mavs Pool Party',
  'pool-party-2026',
  'Join us for the 2026 Mavs Football Pool Party. All teams and parents are welcome, and the Mavs coaching staff and members of the booster club will be there. The booster club provides the mains; parents are asked to donate drinks, desserts, fruit/veggies, sides, and chips. Please make sure to pick your athlete up by 8:00 PM.',
  '2026-08-07 17:00:00-05'::timestamptz,
  '2026-08-07 20:00:00-05'::timestamptz,
  'Pearson Place Pavilion (Avery Ranch)',
  'https://maps.google.com/?q=10000+Ivalenes+Hope+Dr+Austin+TX+78717',
  'published',
  false
);

COMMIT;

-- ===
-- db/migrations/060_remove_rudys_fake_sponsor.sql
-- ===

-- 060_remove_rudys_fake_sponsor.sql
--
-- Removes the "Rudy's BBQ" sponsor seeded by migration 041. It was a
-- placeholder/test row (never a real sponsor) sitting at the MVP tier.
-- Deleting it clears the MVP slot until a real top-tier sponsor is added.
--
-- The 3 sponsor_spotlight hero tiles from 041 (one referenced Rudy's)
-- were already deleted by migration 043, so only the sponsors row remains.

BEGIN;

DELETE FROM sponsors
WHERE name = 'Rudy''s BBQ'
  AND year = '2025-26';

COMMIT;

-- ===
-- db/migrations/061_board_card_update.sql
-- ===

-- 061_board_card_update.sql
--
-- 2026-27 board roster + display changes (spec: docs/specs/board_card_update_spec.md).
--
-- Schema decisions (made against the live schema, not guessed):
--   * Email column already exists: board_members.email_alias (nullable text).
--   * Soft-delete flag already exists: board_members.active (boolean). Chevon is
--     deactivated, not hard-deleted.
--   * Vacancy needs an explicit representation. board_members.name is NOT NULL, so
--     it can't be nulled, and matching a sentinel name string in the UI would be a
--     fragile heuristic. This migration adds an explicit is_vacant boolean instead;
--     the card render keys off the flag.
--
-- Roster changes:
--   1. Chevon Williams (Treasurer)  -> soft-deleted (active = false).
--   2. Ashley Olson "Co-Treasurer"  -> "Treasurer".
--   3. Sylvia Brito (VP of Merchandise) -> vacancy (is_vacant = true, email cleared;
--      role text unchanged per spec).
--   4. Every remaining FILLED 2026-27 member gets the placeholder contact email
--      mcneilfootballboosters@gmail.com. This is the shared booster inbox, used as a
--      placeholder until per-role .org aliases land in J9; see 053 for the same
--      placeholder pattern on site_settings. Reversed by 061_rollback.sql.
--
-- Idempotent: each UPDATE is guarded so a re-run is a no-op.

BEGIN;

-- Explicit vacancy flag (no-op if a prior run already added it).
ALTER TABLE board_members ADD COLUMN IF NOT EXISTS is_vacant boolean NOT NULL DEFAULT false;

-- 1. Soft-delete Chevon Williams.
UPDATE board_members
SET active = false
WHERE year = '2026-27'
  AND name = 'Chevon Williams'
  AND role = 'Treasurer'
  AND active = true;

-- 2. Ashley Olson: Co-Treasurer -> Treasurer.
UPDATE board_members
SET role = 'Treasurer'
WHERE year = '2026-27'
  AND name = 'Ashley Olson'
  AND role = 'Co-Treasurer';

-- 3. Sylvia Brito -> vacancy (role text stays "VP of Merchandise"; no email).
UPDATE board_members
SET is_vacant = true,
    email_alias = NULL
WHERE year = '2026-27'
  AND name = 'Sylvia Brito'
  AND is_vacant = false;

-- 4. Placeholder contact email on every remaining FILLED 2026-27 member.
--    Runs last so the deactivated (Chevon) and vacant (Sylvia) rows are excluded.
UPDATE board_members
SET email_alias = 'mcneilfootballboosters@gmail.com'
WHERE year = '2026-27'
  AND active = true
  AND is_vacant = false;

COMMIT;

-- ===
-- db/migrations/062_coaches_teaching_roles_and_debose.sql
-- ===

-- 062_coaches_teaching_roles_and_debose.sql
--
-- Coaches page updates (2026-27):
--   * New nullable column `teaching_role` holds each coach's RRISD teaching title
--     (e.g. "Social Studies Teacher"). Kept separate from `role` (the football
--     title) and from `bio` (markdown paragraph — Gardner has a real bio; the
--     other coaches don't). The card renders it as a small line under `role`.
--     "Athletics" is dropped from the RRISD directory phrasing as redundant on a
--     coaches page.
--   * Douglas Wallin: add email + teaching_role. Football role unchanged.
--   * Michael Hale: add teaching_role. Email already present.
--   * Reginal Debose: new Defensive Line Coach (position_coach), same group as
--     Wallin.
--   * Jerry Gardner: add email (no teaching_role).
--   * Photos for Wallin, Hale, Debose live in the coach-photos bucket; photo_url
--     stores the full public URL (same convention as Gardner's row).
--
-- Idempotent: column add is IF NOT EXISTS; the INSERT is guarded by NOT EXISTS.

BEGIN;

ALTER TABLE coaches ADD COLUMN IF NOT EXISTS teaching_role text;

-- Jerry Gardner — add email (no teaching_role; he is Head Coach / Athletic Director).
UPDATE coaches
SET email = 'jerry_gardner@roundrockisd.org'
WHERE year = '2026-27' AND name = 'Jerry Gardner';

-- Douglas Wallin — add email + teaching subject + photo.
UPDATE coaches
SET email = 'Douglas_Wallin@roundrockisd.org',
    teaching_role = 'Social Studies Teacher',
    photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachWallinHead.jpg'
WHERE year = '2026-27' AND name = 'Douglas Wallin';

-- Michael Hale — add teaching subject + photo (email already set).
UPDATE coaches
SET teaching_role = 'Physical Education Teacher',
    photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachHaleHead.jpg'
WHERE year = '2026-27' AND name = 'Michael Hale';

-- Reginal Debose — new Defensive Line Coach.
INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Reginal Debose', 'Defensive Line Coach', 'position_coach',
       'reginal_debose@roundrockisd.org', 'Special Education Teacher',
       'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachDeboseHead.jpg',
       15, true
WHERE NOT EXISTS (
  SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Reginal Debose'
);

COMMIT;

-- ===
-- db/migrations/063_fix_ashley_surname.sql
-- ===

-- 063_fix_ashley_surname.sql
--
-- Correct the Treasurer's surname on the 2026-27 board: "Ashley Olson" -> "Ashley Root".
-- Migration 061 carried the old seed surname "Olson" (from migration 010); the board
-- confirmed 2026-06-15 her name is Ashley Root. Name only; role/email unchanged.
-- The /boosters board section revalidates every 60s, so this propagates live without a redeploy.
--
-- Idempotent: re-run is a no-op once the row already reads "Ashley Root".

BEGIN;

UPDATE board_members
SET name = 'Ashley Root'
WHERE year = '2026-27'
  AND name = 'Ashley Olson';

COMMIT;

-- ===
-- db/migrations/064_restore_org_email_addresses.sql
-- ===

-- 064_restore_org_email_addresses.sql
--
-- Cloudflare Email Routing for mcneilmavericks.org is now live (2026-06-15), so
-- the temporary Gmail placeholders come off the public site and the real .org
-- addresses go in. This supersedes migration 053 (the temp boosters@->gmail swap)
-- and replaces the shared-Gmail board placeholder seeded by migration 061.
--
--   * site_settings.primary_contact_email: gmail -> boosters@mcneilmavericks.org
--   * SportsYou resource_links description: gmail -> boosters@mcneilmavericks.org
--   * board_members.email_alias: shared Gmail placeholder -> per-role .org address
--
-- Idempotent: each UPDATE is guarded on the old Gmail value.

BEGIN;

-- General contact (drives Footer + /boosters).
UPDATE site_settings
SET primary_contact_email = 'boosters@mcneilmavericks.org'
WHERE id = 1
  AND primary_contact_email = 'mcneilfootballboosters@gmail.com';

-- SportsYou resource description embeds the contact email in body text.
UPDATE resource_links
SET description = REPLACE(description, 'mcneilfootballboosters@gmail.com', 'boosters@mcneilmavericks.org')
WHERE label = 'SportsYou (Team Messaging)'
  AND description LIKE '%mcneilfootballboosters@gmail.com%';

-- Board cards: map the shared Gmail placeholder to each role's .org address.
UPDATE board_members SET email_alias = 'president@mcneilmavericks.org'
  WHERE year = '2026-27' AND name = 'Carol Glinski' AND email_alias = 'mcneilfootballboosters@gmail.com';

UPDATE board_members SET email_alias = 'treasurer@mcneilmavericks.org'
  WHERE year = '2026-27' AND name = 'Ashley Root' AND email_alias = 'mcneilfootballboosters@gmail.com';

UPDATE board_members SET email_alias = 'secretary@mcneilmavericks.org'
  WHERE year = '2026-27' AND name = 'Jeremy Vest' AND email_alias = 'mcneilfootballboosters@gmail.com';

UPDATE board_members SET email_alias = 'vicepresident@mcneilmavericks.org'
  WHERE year = '2026-27' AND name IN ('Kendra Jalbert', 'Shannon Schoepflin') AND email_alias = 'mcneilfootballboosters@gmail.com';

UPDATE board_members SET email_alias = 'membership@mcneilmavericks.org'
  WHERE year = '2026-27' AND name = 'Debby Mata' AND email_alias = 'mcneilfootballboosters@gmail.com';

UPDATE board_members SET email_alias = 'boosters@mcneilmavericks.org'
  WHERE year = '2026-27' AND name = 'Monica Woods' AND email_alias = 'mcneilfootballboosters@gmail.com';

COMMIT;

-- ===
-- db/migrations/065_pool_party_relocate_morningside.sql
-- ===

-- 065_pool_party_relocate_morningside.sql
--
-- Relocates the 2026 McNeil Mavs Pool Party (seeded in 059) to Morningside Pool
-- in Avery Ranch. Date/time unchanged (Fri Aug 7 2026, 5:00-8:00 PM CDT).
--
-- New venue: Morningside Pool (Avery Ranch)
--   14100 Morgan Creek Dr, Austin, TX 78717

BEGIN;

UPDATE events
SET
  location = 'Morningside Pool (Avery Ranch)',
  location_url = 'https://maps.google.com/?q=14100+Morgan+Creek+Dr+Austin+TX+78717'
WHERE slug = 'pool-party-2026';

COMMIT;

-- ===
-- db/migrations/066_coach_justin_ward.sql
-- ===

-- 066_coach_justin_ward.sql
--
-- Coaches page update (2026-27):
--   * Justin Ward: new Receiver Coach (position_coach), same group as Debose/Wallin.
--     teaching_role drops "& Athletics" per the 062 RRISD-directory convention.
--     sort_order = 20 (next position_coach slot after Debose's 15).
--   * Photo lives in the coach-photos bucket as CoachWard.jpg (verified the exact
--     object name + casing against the bucket; it is NOT CoachWardHead.jpg and the
--     lowercase coachward.jpg 404s). photo_url stores the full public URL, same
--     convention as the 062 rows.
--
-- Idempotent: the INSERT is guarded by NOT EXISTS, same as the Debose insert in 062.

BEGIN;

-- Justin Ward — new Receiver Coach.
INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Justin Ward', 'Receiver Coach', 'position_coach',
       'Justin_Ward@roundrockisd.org', 'Physical Education Teacher',
       'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachWard.jpg',
       20, true
WHERE NOT EXISTS (
  SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Justin Ward'
);

COMMIT;

-- ===
-- db/migrations/067_add_scoreboard_tier.sql
-- ===

-- 067_add_scoreboard_tier.sql
--
-- Adds a 6th sponsorship tier for 2025-26: "Scoreboard" ($5,000, 2-year commitment).
-- Puts the sponsor's logo on the McNeil HS stadium scoreboard for two full seasons.
-- Unlike the other tiers it carries a short summary instead of a perk list: perks is
-- left empty ('[]'). The description holds two paragraphs separated by a blank line —
-- the first ("Two Years") renders as the gray-italic subtitle under the name (matching
-- MVP's "Top sponsor..." tagline), the rest renders as the card body. badge_label
-- highlights the premier / two-year nature without clashing with the $5,000 MVP tier.
--
-- sort_order = 6 (after Blue=5) so the price-based 3-over-3 card split on /boosters/sponsor
-- puts Scoreboard last in the large bottom row (Diamond, MVP, Scoreboard).
--
-- Idempotent: guarded by NOT EXISTS.

BEGIN;

INSERT INTO sponsorship_tiers (year, name, price_cents, description, perks, sort_order, badge_label, active)
SELECT '2025-26', 'Scoreboard', 500000,
       'Two Years

Your business logo on the McNeil HS stadium scoreboard for two full seasons — front and center for every fan at every home game. Our most visible, longest-running sponsorship.',
       '[]'::jsonb,
       6, 'Premier · 2 Years', true
WHERE NOT EXISTS (
  SELECT 1 FROM sponsorship_tiers WHERE year = '2025-26' AND name = 'Scoreboard'
);

COMMIT;

-- ===
-- db/migrations/068_payments_provider_agnostic.sql
-- ===

-- 068_payments_provider_agnostic.sql
--
-- Renames the Stripe-specific columns on `payments` to provider-agnostic names and
-- adds a `payment_provider` column, ahead of wiring Square (Step 9/10). Migration 004
-- created the table when Stripe was the planned processor; the board switched to Square
-- 2026-05-26. Square uses different ID concepts (order_id, payment_id) than Stripe
-- (session_id, payment_intent_id), so the column NAMES need to stop implying Stripe
-- before any payment code lands — otherwise the webhook handler would be writing
-- Square IDs into columns named `stripe_*`.
--
--   stripe_session_id        -> payment_session_id   (Square order_id / Stripe session id)
--   stripe_payment_intent_id -> payment_provider_id  (Square payment_id / Stripe intent id)
--   + payment_provider text NOT NULL DEFAULT 'square'
--
-- Backing UNIQUE constraints (auto-named payments_stripe_*_key) are renamed to match so
-- nothing in the schema still says "stripe".
--
-- NOT in scope (deliberately deferred — semantic decision, not hygiene): the
-- `payment_method_type` enum still carries the value 'stripe'. Whether that becomes
-- 'square', a generic 'online', or coexists with the new `payment_provider` column is a
-- data-model call to make before Step 9, not bundled into this rename. No rows use the
-- enum yet (no payment code exists), so it can change cleanly whenever decided.
--
-- No application/TS code references the old column names (grep 2026-07-05: stripe appears
-- only in docs + historical migrations), so this migration is DB-only.
--
-- Idempotent: every step guards on existence, safe to re-run.

BEGIN;

DO $$
BEGIN
  -- Rename columns (only if the old name is still present)
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'payments' AND column_name = 'stripe_session_id') THEN
    ALTER TABLE payments RENAME COLUMN stripe_session_id TO payment_session_id;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'payments' AND column_name = 'stripe_payment_intent_id') THEN
    ALTER TABLE payments RENAME COLUMN stripe_payment_intent_id TO payment_provider_id;
  END IF;

  -- Rename the backing UNIQUE constraints (and their indexes) to drop "stripe"
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_stripe_session_id_key') THEN
    ALTER TABLE payments RENAME CONSTRAINT payments_stripe_session_id_key
      TO payments_payment_session_id_key;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_stripe_payment_intent_id_key') THEN
    ALTER TABLE payments RENAME CONSTRAINT payments_stripe_payment_intent_id_key
      TO payments_payment_provider_id_key;
  END IF;
END $$;

-- New column: which processor handled the payment
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payment_provider text NOT NULL DEFAULT 'square';

-- Refresh column comments to be provider-agnostic
COMMENT ON COLUMN payments.payment_session_id IS
  'Provider checkout/session identifier (Square order_id, or Stripe session id historically). Unique. Null for manual cash/check entries.';
COMMENT ON COLUMN payments.payment_provider_id IS
  'Provider-side payment identifier (Square payment_id, or Stripe payment_intent historically). Unique. Null for manual entries.';
COMMENT ON COLUMN payments.payment_provider IS
  'Which processor handled this payment: square (default), paypal, stripe (legacy). Informational for cash/check rows.';

-- Historical comment on sponsors.payment_id (set in migration 004) still says "Stripe"
COMMENT ON COLUMN sponsors.payment_id IS
  'Links the sponsor''s inbound payment to the sponsor record for Treasurer reconciliation. Nullable for manual or legacy entries.';

COMMIT;

-- ===
-- db/migrations/069_payment_method_add_square.sql
-- ===

-- 069_payment_method_add_square.sql
--
-- Adds 'square' to the payment_method_type enum. Migration 068 renamed the
-- Stripe-specific COLUMNS to provider-agnostic names but deliberately left the
-- enum alone (flagged as a semantic decision). This is that decision, made in
-- the additive/low-risk direction: add 'square' as a method value, keep the
-- legacy 'stripe' value in place (tolerate, don't migrate — no rows use it, and
-- dropping an enum value in Postgres requires recreating the whole type).
--
-- The enum records HOW a payment was made; 'square' joins the existing
-- ('stripe', 'cash', 'check', 'zero_dollar', 'other'). This mirrors how 'stripe'
-- was itself a provider-as-method value, so it's consistent with the original
-- design. The separate payments.payment_provider column (added in 068) still
-- carries the provider string too; for online card payments the two agree
-- ('square'), while cash/check rows use method='cash'/'check' with
-- payment_provider left at its default (informational only for those).
--
-- Idempotent via IF NOT EXISTS. Single DDL, no transaction wrapper needed.

ALTER TYPE payment_method_type ADD VALUE IF NOT EXISTS 'square';

-- ===
-- db/migrations/070_events_seed_senior_photo_shoot_2026.sql
-- ===

-- 070_events_seed_senior_photo_shoot_2026.sql
--
-- Seeds the 2026 Senior Photo Shoot (senior football players + cheerleaders)
-- as a published upcoming event on /events. Same column set and CDT offset
-- convention as 059_events_seed_pool_party_2026.sql.
--
-- Jul 26, 2026 falls inside Central Daylight Time, so the offset is -05.
-- Exact start time is TBD pending the photographer's lighting check; the
-- 8:00-9:00 AM window is the confirmed morning range and the description
-- carries the TBD note. Update starts_at/ends_at once the time is set.
-- Location is McNeil High School (5720 McNeil Drive, Austin, TX 78729).

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
) VALUES
(
  'Senior Photo Shoot (Football & Cheer)',
  'senior-photo-shoot-2026',
  'Photo shoot for senior football players and cheerleaders at McNeil High School. Exact start time is TBD until the photographer confirms lighting, but it will be in the morning between 8:00 and 9:00 AM. We will update this page as soon as the time is confirmed.',
  '2026-07-26 08:00:00-05'::timestamptz,
  '2026-07-26 09:00:00-05'::timestamptz,
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
);

COMMIT;

-- ===
-- db/migrations/071_events_seed_july_2026_slate.sql
-- ===

-- 071_events_seed_july_2026_slate.sql
--
-- Seeds 5 late-July 2026 events as published rows on /events, following the
-- seed pattern of 048_events_seed.sql / 059_events_seed_pool_party_2026.sql.
-- All dates fall inside Central Daylight Time, so the offset is -05.
-- Weekdays verified against the 2026 calendar: Jul 22 Wed, Jul 24 Fri,
-- Jul 27 Mon, Jul 29 Wed, Jul 30 Thu.
--
-- Notes:
--   * Parent & Athlete Meeting: real start time not yet announced. starts_at
--     is NOT NULL and the UI always renders a time, so 6:00 PM is seeded as a
--     placeholder with "(Time TBA)" in the title (Jeremy 2026-07-17). Patch
--     starts_at/ends_at + strip the title suffix + TBA sentence once Coach
--     posts the time.
--   * Equipment pickups: description embeds a Markdown link to the RankOne
--     forms portal (URL from migration 035). Renders as a link on the event
--     detail page (ReactMarkdown); shows as raw markdown in the list view's
--     clamped preview and the ICS feed, so it sits last in the description.
--   * Meet the Mavs and scrimmages intentionally excluded (dates contested;
--     separate migration later). Pool party already seeded by 059/065.

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
) VALUES
(
  'Stronger Together: McNeil Football x Rice Football',
  'rice-mcneil-stronger-together',
  'A joint character and leadership session with Rice University Football, with Rice players joining virtually. Open to sophomores, juniors, and seniors only. Pizza will be served at 11:30 AM, and the program begins at 1:00 PM. Sponsored by the McNeil Football Booster Club.',
  '2026-07-22 13:00:00-05'::timestamptz,
  NULL,
  'Team Room G204, McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  '7th-9th Grade Football Camp',
  'youth-football-camp-2026',
  'Football camp for 7th, 8th, and 9th graders hosted by McNeil Football. Please arrive by 7:50 AM.',
  '2026-07-24 08:00:00-05'::timestamptz,
  '2026-07-24 11:00:00-05'::timestamptz,
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  'Parent & Athlete Meeting (Time TBA)',
  'parent-athlete-meeting-2026',
  'Meeting for parents and athletes ahead of the 2026 season. The start time is TBA and will be posted here as soon as it is announced. Check back for updates.',
  '2026-07-27 18:00:00-05'::timestamptz,
  NULL,
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  'Equipment Pickup - Seniors',
  'senior-equipment-pickup-2026',
  'Equipment pickup for seniors only. All RankOne athletic forms must be complete ("all green") before any equipment can be issued. Forms are available through [RRISD Athletic Forms](https://roundrockisd.rankone.com/New/NewInstructionsPage.aspx).',
  '2026-07-29 10:00:00-05'::timestamptz,
  '2026-07-29 11:00:00-05'::timestamptz,
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  'Equipment Pickup - Juniors & Sophomores',
  'jr-soph-equipment-pickup-2026',
  'Equipment pickup for juniors and sophomores. All RankOne athletic forms must be complete ("all green") before any equipment can be issued. Forms are available through [RRISD Athletic Forms](https://roundrockisd.rankone.com/New/NewInstructionsPage.aspx).',
  '2026-07-30 10:00:00-05'::timestamptz,
  '2026-07-30 13:00:00-05'::timestamptz,
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
);

COMMIT;

-- ===
-- db/migrations/072_photo_shoot_confirmed_time.sql
-- ===

-- 072_photo_shoot_confirmed_time.sql
--
-- The Senior Photo Shoot time is confirmed (Amanda, cheer boosters,
-- 2026-07-20): Sunday July 26 at 10:30 AM, meet at the McNeil entrance in
-- jerseys and jeans. Replaces the provisional 8:00-9:00 AM window and the
-- TBD note seeded by migration 070. Adds the Spirit Book context and the
-- senior-ad order form link ($25 per quarter page); the form URL renders
-- as a link on the event detail page (ReactMarkdown, same pattern as the
-- RankOne link in 071).
--
-- No end time was announced, so ends_at goes to NULL (the UI renders a
-- bare start time in that case).

BEGIN;

UPDATE events SET
  starts_at = '2026-07-26 10:30:00-05'::timestamptz,
  ends_at = NULL,
  description = 'Senior football players and cheerleaders are featured on the cover of the Spirit Book, the program produced by the cheer boosters. Seniors should meet at the entrance of McNeil High School at 10:30 AM wearing jerseys and jeans. Senior ads in the program are available for $25 per quarter page: [reserve a senior ad here](https://docs.google.com/forms/d/e/1FAIpQLScGDI6gHk6-hyVJDBxrZAwiNpQwLDeHzjQ74Npg57nwvKjCSQ/viewform).'
WHERE slug = 'senior-photo-shoot-2026';

COMMIT;

-- ===
-- db/migrations/073_resources_add_mailing_list.sql
-- ===

-- 073_resources_add_mailing_list.sql
--
-- Adds "Join Our Mailing List" to /resources (Forms & Links) under
-- News & Communications, ABOVE MavMail (MavMail is sort_order=-2, so this
-- row takes -3). Links to the booster membership Google Form (the same URL
-- as BOOSTER_FORM_URL in lib/constants.ts) — Jeremy 2026-07-20: the
-- membership form is the email-collection channel for club communications.
-- icon_hint='form' (ClipboardList) rather than 'mail' so it doesn't
-- duplicate MavMail's mail icon directly below it.
--
-- The same link ships in the site footer (code change, Footer.tsx) with
-- identical "Join Our Mailing List" label.

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
VALUES (
  'communications',
  'Join Our Mailing List',
  'https://docs.google.com/forms/d/e/1FAIpQLSfJXyssXItMv8EUU3FHkPqMo_9DGpReNlUq283NimBwa-rx1Q/viewform',
  'Get booster club news, game-day updates, and volunteer opportunities by email.',
  'form',
  -3,
  true
);

COMMIT;

-- ===
-- db/migrations/074_sponsorship_levels_overhaul.sql
-- ===

-- 074_sponsorship_levels_overhaul.sql
--
-- Sponsorship page content overhaul per Kendra's spec (2026-07-17), Phase A
-- (copy / pricing / data only — no inquiry form yet).
--
-- Restructures sponsorship_tiers into 6 BASE levels + 2 ADD-ONS:
--   Base:    Blue $500, Gold $1,000, Platinum $1,500, Diamond $2,500,
--            MVP $5,000, Custom (flexible).
--   Add-ons: Tunnel $350 (per season), Scoreboard $3,000 (two seasons).
--
-- Schema additions (approved 2026-07-20 — the "3 explicit columns" model):
--   is_addon       — true for Tunnel/Scoreboard so the page renders them in
--                    a separate Add-Ons section (selectable alone or with a base).
--   price_flexible — true for Custom; the card shows "Custom" instead of "$0".
--   term_label     — "per season" / "two seasons"; rendered on a price-adjacent
--                    line so the term stays OUT of the benefit bullets.
-- All three are backward-compatible (defaults keep existing rows unchanged).
--
-- Also: every "Game program" perk is removed (the base perk arrays are rewritten
-- wholesale below). Benefit bullets are fully enumerated per tier — commercial
-- counts change per tier (2 -> 4 -> 6), so cumulative "everything in X" phrasing
-- would misread as additive.
--
-- Operates on year 2025-26 (site_settings.current_year; the year the sponsor
-- pages read). Idempotent: base tiers UPDATE in place, add-ons INSERT-if-absent.

BEGIN;

-- 1. Schema: three explicit columns.
ALTER TABLE sponsorship_tiers
  ADD COLUMN IF NOT EXISTS is_addon boolean NOT NULL DEFAULT false;
ALTER TABLE sponsorship_tiers
  ADD COLUMN IF NOT EXISTS price_flexible boolean NOT NULL DEFAULT false;
ALTER TABLE sponsorship_tiers
  ADD COLUMN IF NOT EXISTS term_label text;

-- 2. Base tiers (rewrite perks, confirm price, set term/sort, clear add-on flags).
UPDATE sponsorship_tiers SET
  price_cents = 50000,
  perks = '["Logo and link on the McNeil Mavericks website", "Social media and newsletter promotion", "Public address announcement at games"]'::jsonb,
  description = NULL,
  badge_label = NULL,
  is_addon = false,
  price_flexible = false,
  term_label = 'per season',
  sort_order = 1
WHERE year = '2025-26' AND name = 'Blue';

UPDATE sponsorship_tiers SET
  price_cents = 100000,
  perks = '["Logo and link on the McNeil Mavericks website", "Social media and newsletter promotion", "Public address announcement at games", "Field sign at all McNeil varsity games and all home freshman and JV games", "Business sign on McNeil Drive"]'::jsonb,
  description = NULL,
  badge_label = NULL,
  is_addon = false,
  price_flexible = false,
  term_label = 'per season',
  sort_order = 2
WHERE year = '2025-26' AND name = 'Gold';

UPDATE sponsorship_tiers SET
  price_cents = 150000,
  perks = '["Logo and link on the McNeil Mavericks website", "Social media and newsletter promotion", "Public address announcement at games", "Field sign at all McNeil varsity games and all home freshman and JV games", "Business sign on McNeil Drive", "Two 30-second audio commercials per game"]'::jsonb,
  description = NULL,
  badge_label = 'Recommended',
  is_addon = false,
  price_flexible = false,
  term_label = 'per season',
  sort_order = 3
WHERE year = '2025-26' AND name = 'Platinum';

UPDATE sponsorship_tiers SET
  price_cents = 250000,
  perks = '["Logo and link on the McNeil Mavericks website", "Social media and newsletter promotion", "Public address announcement at games", "Field sign at all McNeil varsity games and all home freshman and JV games", "Business sign on McNeil Drive", "Streaming banner at all games", "Four 30-second audio commercials per game"]'::jsonb,
  description = NULL,
  badge_label = NULL,
  is_addon = false,
  price_flexible = false,
  term_label = 'per season',
  sort_order = 4
WHERE year = '2025-26' AND name = 'Diamond';

UPDATE sponsorship_tiers SET
  price_cents = 500000,
  perks = '["Maximum visibility across the McNeil Football program", "Logo and link on the McNeil Mavericks website", "Field sign at games and business sign on McNeil Drive", "Social media and newsletter promotion", "Public address announcement at home games", "Streaming banner at all games", "Six 30-second audio commercials per game"]'::jsonb,
  description = NULL,
  badge_label = NULL,
  is_addon = false,
  price_flexible = false,
  term_label = 'per season',
  sort_order = 5
WHERE year = '2025-26' AND name = 'MVP';

-- 3. Custom (flexible base level). INSERT if absent.
INSERT INTO sponsorship_tiers (name, price_cents, description, perks, sort_order, active, year, badge_label, is_addon, price_flexible, term_label)
SELECT 'Custom', 0,
  E'Flexible sponsorship\n\nCustom packages and in-kind ideas are encouraged. Tell us what your business is looking for and we''ll build a sponsorship that fits.',
  '[]'::jsonb, 6, true, '2025-26', NULL, false, true, 'per season'
WHERE NOT EXISTS (
  SELECT 1 FROM sponsorship_tiers WHERE year = '2025-26' AND name = 'Custom'
);

-- 4. Tunnel add-on ($350 per season). INSERT if absent.
INSERT INTO sponsorship_tiers (name, price_cents, description, perks, sort_order, active, year, badge_label, is_addon, price_flexible, term_label)
SELECT 'Tunnel', 35000,
  E'Homecoming Tunnel Stampede\n\nYour business recognized as the sponsor of the Homecoming Tunnel Stampede as the Mavs take the field.',
  '[]'::jsonb, 7, true, '2025-26', NULL, true, false, 'per season'
WHERE NOT EXISTS (
  SELECT 1 FROM sponsorship_tiers WHERE year = '2025-26' AND name = 'Tunnel'
);

-- 5. Scoreboard add-on ($3,000 for two seasons). Row exists; UPDATE in place.
--    Venue clarification required; no payment/"paid upfront" language.
UPDATE sponsorship_tiers SET
  price_cents = 300000,
  perks = '[]'::jsonb,
  description = E'Scoreboard logo\n\nYour logo on the McNeil Stadium scoreboard for two full seasons. The scoreboard is at McNeil Stadium, and varsity home games are played at KRAC, so this exposure is primarily at freshman and JV games played at McNeil Stadium.',
  badge_label = NULL,
  is_addon = true,
  price_flexible = false,
  term_label = 'two seasons',
  sort_order = 8
WHERE year = '2025-26' AND name = 'Scoreboard';

COMMIT;

-- ===
-- db/migrations/075_coaches_2026_offensive_staff.sql
-- ===

-- 075_coaches_2026_offensive_staff.sql
--
-- Coaches page update (2026-27): five new football staff hires.
--   Coordinators (role_category='coordinator'):
--     * Alexander Gillis — Assistant Head Coach / Offensive Coordinator.
--       sort_order 4 (ahead of Hale's 5 — the senior coordinator).
--     * Barrett Matthews — Special Teams & Pass Game Coordinator. sort_order 6.
--   Position coaches (role_category='position_coach', after Ward's 20):
--     * Thomas Umberger — Wide Receivers Coach. sort_order 25.
--     * Ryan Doyle — Offensive Line Coach. sort_order 30.
--     * Devonte Jones — Defensive Backs Coach. sort_order 35.
--
-- Emails + teaching roles: only Doyle and Jones are in the RRISD staff directory
-- (verified 2026-07-21) — Doyle = Physical Education, Jones = Special Education,
-- teaching_role in the "{Dept} Teacher" style per the 062/066 convention. Gillis,
-- Matthews, and Umberger are not in the district directory yet, so their email +
-- teaching_role are left NULL (not fabricated) — fill when available.
--
-- No photos yet: the RRISD directory hosts no real headshots (logo placeholder
-- for everyone), so photo_url is NULL and the CoachCard renders its initials
-- fallback. Drop real photos into the coach-photos bucket + set photo_url later.
--
-- Idempotent: each INSERT is guarded by NOT EXISTS on (year, name), same as 062/066.

BEGIN;

INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Alexander Gillis', 'Assistant Head Coach / Offensive Coordinator', 'coordinator',
       NULL, NULL, NULL, 4, true
WHERE NOT EXISTS (SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Alexander Gillis');

INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Barrett Matthews', 'Special Teams & Pass Game Coordinator', 'coordinator',
       NULL, NULL, NULL, 6, true
WHERE NOT EXISTS (SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Barrett Matthews');

INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Thomas Umberger', 'Wide Receivers Coach', 'position_coach',
       NULL, NULL, NULL, 25, true
WHERE NOT EXISTS (SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Thomas Umberger');

INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Ryan Doyle', 'Offensive Line Coach', 'position_coach',
       'Ryan_Doyle@roundrockisd.org', 'Physical Education Teacher', NULL, 30, true
WHERE NOT EXISTS (SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Ryan Doyle');

INSERT INTO coaches (year, name, role, role_category, email, teaching_role, photo_url, sort_order, active)
SELECT '2026-27', 'Devonte Jones', 'Defensive Backs Coach', 'position_coach',
       'devonte_jones@roundrockisd.org', 'Special Education Teacher', NULL, 35, true
WHERE NOT EXISTS (SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Devonte Jones');

COMMIT;

-- ===
-- db/migrations/076_coach_ward_running_backs.sql
-- ===

-- 076_coach_ward_running_backs.sql
--
-- Justin Ward moves from Receiver Coach to Running Backs Coach (2026-27).
-- Resolves the two-receivers overlap created by migration 075 (Umberger came
-- on as Wide Receivers Coach); Ward now owns RBs, Umberger owns WRs.
-- "Running Backs" is two words (standard spelling). role_category, email,
-- teaching_role, photo, and sort_order all unchanged.
--
-- Idempotent: guarded on the old role value.

BEGIN;

UPDATE coaches
SET role = 'Running Backs Coach'
WHERE year = '2026-27'
  AND name = 'Justin Ward'
  AND role = 'Receiver Coach';

COMMIT;

-- ===
-- db/migrations/077_practice_schedules_2026_preseason.sql
-- ===

-- 077_practice_schedules_2026_preseason.sql
--
-- Seeds the 2026-27 preseason practice schedule (from the coaches' July-August
-- 2026 calendar). Player-facing detail only: daily team practice times + key
-- markers (first day of practice/school, picture day, intrasquad scrimmage,
-- pool party). Coach-internal items (PD, coaches meetings, work week, scout
-- input, class periods) are intentionally omitted.
--
-- Year is 2026-27: the practice page now reads current_schedule_year (the season
-- being played), matching games/coaches — not current_year (the roster year).
-- Varsity and JV practice together, so they share one body; Freshmen differ.
-- Opponent scrimmages + Game 1 live on the games schedule (migration 078); the
-- tables here just point to it on those days.
--
-- Idempotent: INSERT-if-absent on (year, team_level).

BEGIN;

-- Varsity + JV (identical times) --------------------------------------------
INSERT INTO practice_schedules (year, team_level, body, source_note, active)
SELECT '2026-27', 'varsity', $body$Varsity and JV practice together. Times are AM unless noted and are subject to change. See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
| Mon Aug 3 | 7:30–11:00 | First day of practice |
| Tue Aug 4 | 6:00–9:30 | |
| Wed Aug 5 | 7:30–11:00 | |
| Thu Aug 6 | 7:30–11:00 | |
| Fri Aug 7 | 7:30–11:00 | Pool party 5:00–8:00 PM |
| Sat Aug 8 | 7:30–9:30 | Intrasquad scrimmage |
| Mon Aug 10 | 6:30–10:00 | |
| Tue Aug 11 | 6:30–10:00 | |
| Wed Aug 12 | 6:30–10:00 | |
| Thu Aug 13 | See Games | Scrimmage vs Hendrickson (home) |
| Fri Aug 14 | 7:00–10:00 | |
| Sat Aug 15 | 9:00–11:00 | |
| Mon Aug 17 | 6:30–10:00 | |
| Tue Aug 18 | 6:30–10:00 | |
| Wed Aug 19 | 6:20–8:15 | First day of school |
| Thu Aug 20 | See Games | Scrimmage vs Eastview (home), time TBD |
| Fri Aug 21 | 7:00–8:00 | Picture day |
| Mon Aug 24 | 6:00–8:15 | |
| Tue Aug 25 | 6:00–8:15 | |
| Wed Aug 26 | 6:20–8:15 | |
| Thu Aug 27 | 7:50–8:30 | |
| Fri Aug 28 | See Games | Game 1 at Bowie (away) |
$body$, NULL, true
WHERE NOT EXISTS (SELECT 1 FROM practice_schedules WHERE year='2026-27' AND team_level='varsity');

INSERT INTO practice_schedules (year, team_level, body, source_note, active)
SELECT '2026-27', 'jv', $body$Varsity and JV practice together. Times are AM unless noted and are subject to change. See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
| Mon Aug 3 | 7:30–11:00 | First day of practice |
| Tue Aug 4 | 6:00–9:30 | |
| Wed Aug 5 | 7:30–11:00 | |
| Thu Aug 6 | 7:30–11:00 | |
| Fri Aug 7 | 7:30–11:00 | Pool party 5:00–8:00 PM |
| Sat Aug 8 | 7:30–9:30 | Intrasquad scrimmage |
| Mon Aug 10 | 6:30–10:00 | |
| Tue Aug 11 | 6:30–10:00 | |
| Wed Aug 12 | 6:30–10:00 | |
| Thu Aug 13 | See Games | Scrimmage vs Hendrickson (home) |
| Fri Aug 14 | 7:00–10:00 | |
| Sat Aug 15 | 9:00–11:00 | |
| Mon Aug 17 | 6:30–10:00 | |
| Tue Aug 18 | 6:30–10:00 | |
| Wed Aug 19 | 6:20–8:15 | First day of school |
| Thu Aug 20 | See Games | Scrimmage vs Eastview (home), time TBD |
| Fri Aug 21 | 7:00–8:00 | Picture day |
| Mon Aug 24 | 6:00–8:15 | |
| Tue Aug 25 | 6:00–8:15 | |
| Wed Aug 26 | 6:20–8:15 | |
| Thu Aug 27 | 7:50–8:30 | |
| Fri Aug 28 | See Games | Game 1 at Bowie (away) |
$body$, NULL, true
WHERE NOT EXISTS (SELECT 1 FROM practice_schedules WHERE year='2026-27' AND team_level='jv');

-- Freshmen ------------------------------------------------------------------
INSERT INTO practice_schedules (year, team_level, body, source_note, active)
SELECT '2026-27', 'freshman', $body$Freshmen practice times. Times are subject to change. See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
| Mon Aug 3 | 10:00–12:00 | First day of practice |
| Tue Aug 4 | 8:30–10:30 (or 6:30–8:30 PM) | |
| Wed Aug 5 | 10:00–12:00 | |
| Thu Aug 6 | 10:00–12:00 | |
| Fri Aug 7 | 10:00–12:00 | Pool party 5:00–8:00 PM |
| Sat Aug 8 | 9:00–10:30 | Intrasquad scrimmage |
| Mon Aug 10 | 9:00–11:00 | |
| Tue Aug 11 | 9:00–11:00 | |
| Wed Aug 12 | 9:00–11:00 (or 6:30–8:30 PM) | |
| Thu Aug 13 | See Games | Scrimmage vs Hendrickson (home) |
| Fri Aug 14 | 9:00–11:00 | |
| Sat Aug 15 | No practice | |
| Mon Aug 17 | 9:00–11:00 | |
| Tue Aug 18 | 9:00–11:00 | |
| Wed Aug 19 | 8:10–9:45 | First day of school |
| Thu Aug 20 | See Games | Scrimmage vs Eastview (home), time TBD |
| Fri Aug 21 | 8:00–10:15 | Picture day |
| Mon Aug 24 | 8:10–9:50 | |
| Tue Aug 25 | 8:10–9:50 | |
| Wed Aug 26 | 8:10–9:50 | |
| Thu Aug 27 | 8:45–9:50 | |
| Fri Aug 28 | 8:30–9:50 | Game 1 at Bowie (away) |
$body$, NULL, true
WHERE NOT EXISTS (SELECT 1 FROM practice_schedules WHERE year='2026-27' AND team_level='freshman');

COMMIT;

-- ===
-- db/migrations/078_preseason_scrimmages_2026.sql
-- ===

-- 078_preseason_scrimmages_2026.sql
--
-- Adds the two 2026 preseason opponent scrimmages to the games schedule (these
-- were the "Aug 13 / Aug 20 preseason TBD" slots migration 057 omitted for lack
-- of an opponent). Both are HOME; notes = 'Scrimmage'. Per the coaches' calendar:
--   * Thu Aug 13 vs Hendrickson — firm times: Varsity 7:00 PM, JV + Freshmen
--     5:30 PM. result_status = 'scheduled'.
--   * Thu Aug 20 vs Eastview — time TBD in the source, so result_status = 'tbd'
--     (the games views now render "TBD" in the time cell for tbd games). The
--     stored game_date time is a nominal placeholder; the date (Aug 20) is real.
-- Freshmen rows are mirrored Green + Blue at the single advertised time, matching
-- the migration 032 convention. Venue (KRAC vs McNeil Stadium) is unknown for a
-- scrimmage, so location is left NULL.
--
-- August 2026 is CDT (-05). Game 1 vs Bowie (Aug 28) is already seeded (057) —
-- not touched here. Idempotent: INSERT-if-absent per (year, team_level,
-- team_designation, opponent, game_date).

BEGIN;

-- Thu Aug 13 vs Hendrickson (HOME) — firm times ------------------------------
INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'varsity', NULL, 'Hendrickson High School', '2026-08-13 19:00:00-05'::timestamptz, 'home', 'scheduled', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='varsity' AND team_designation IS NULL AND opponent='Hendrickson High School' AND game_date='2026-08-13 19:00:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'jv', NULL, 'Hendrickson High School', '2026-08-13 17:30:00-05'::timestamptz, 'home', 'scheduled', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='jv' AND team_designation IS NULL AND opponent='Hendrickson High School' AND game_date='2026-08-13 17:30:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'freshman', 'Green', 'Hendrickson High School', '2026-08-13 17:30:00-05'::timestamptz, 'home', 'scheduled', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='freshman' AND team_designation='Green' AND opponent='Hendrickson High School' AND game_date='2026-08-13 17:30:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'freshman', 'Blue', 'Hendrickson High School', '2026-08-13 17:30:00-05'::timestamptz, 'home', 'scheduled', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='freshman' AND team_designation='Blue' AND opponent='Hendrickson High School' AND game_date='2026-08-13 17:30:00-05'::timestamptz);

-- Thu Aug 20 vs Eastview (HOME) — time TBD -----------------------------------
INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'varsity', NULL, 'Eastview High School', '2026-08-20 18:00:00-05'::timestamptz, 'home', 'tbd', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='varsity' AND team_designation IS NULL AND opponent='Eastview High School' AND game_date='2026-08-20 18:00:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'jv', NULL, 'Eastview High School', '2026-08-20 18:00:00-05'::timestamptz, 'home', 'tbd', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='jv' AND team_designation IS NULL AND opponent='Eastview High School' AND game_date='2026-08-20 18:00:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'freshman', 'Green', 'Eastview High School', '2026-08-20 18:00:00-05'::timestamptz, 'home', 'tbd', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='freshman' AND team_designation='Green' AND opponent='Eastview High School' AND game_date='2026-08-20 18:00:00-05'::timestamptz);

INSERT INTO games (year, team_level, team_designation, opponent, game_date, home_or_away, result_status, notes)
SELECT '2026-27', 'freshman', 'Blue', 'Eastview High School', '2026-08-20 18:00:00-05'::timestamptz, 'home', 'tbd', 'Scrimmage'
WHERE NOT EXISTS (SELECT 1 FROM games WHERE year='2026-27' AND team_level='freshman' AND team_designation='Blue' AND opponent='Eastview High School' AND game_date='2026-08-20 18:00:00-05'::timestamptz);

COMMIT;

-- ===
-- db/migrations/079_parent_meeting_confirmed_time.sql
-- ===

-- 079_parent_meeting_confirmed_time.sql
--
-- The Parent & Athlete Meeting time is confirmed by the coaches' calendar:
-- Mon July 27 2026, 6:30-8:00 PM. Replaces the 6:00 PM placeholder + "(Time TBA)"
-- title seeded by migration 071. July 27 is CDT (-05).
--
-- Idempotent: guarded on the placeholder title.

BEGIN;

UPDATE events SET
  starts_at = '2026-07-27 18:30:00-05'::timestamptz,
  ends_at = '2026-07-27 20:00:00-05'::timestamptz,
  title = 'Parent & Athlete Meeting',
  description = 'Meeting for parents and athletes ahead of the 2026 season at McNeil High School.'
WHERE slug = 'parent-athlete-meeting-2026'
  AND title = 'Parent & Athlete Meeting (Time TBA)';

COMMIT;

-- ===
-- db/migrations/080_parent_meeting_location_details.sql
-- ===

-- 080_parent_meeting_location_details.sql
--
-- Adds the location + fuller description to the Parent & Athlete Meeting from
-- Coach Gardner's Facebook event: the meeting is in the McNeil HS Cafeteria,
-- and the agenda covers the practice schedule, program expectations, and
-- staffing. Date/time (Mon Jul 27, 6:30 PM) already set by migration 079.
--
-- Idempotent: guarded on the slug + the 079 description (so it only patches the
-- row still holding the location-less description).

BEGIN;

UPDATE events SET
  location = 'McNeil High School Cafeteria',
  location_url = 'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  description = 'Coach Gardner invites all football players and parents to kick off the 2026-27 season. The meeting is at 6:30 PM in the cafeteria at McNeil High School. The agenda includes the practice schedule, program expectations, and staffing.'
WHERE slug = 'parent-athlete-meeting-2026'
  AND description = 'Meeting for parents and athletes ahead of the 2026 season at McNeil High School.';

COMMIT;

-- ===
-- db/migrations/081_pool_party_signup_and_address.sql
-- ===

-- 081_pool_party_signup_and_address.sql
--
-- Pool Party (Fri Aug 7 2026) updates from the official booster flyer:
--   * Add the SignUpGenius link (donated-food signup) as signup_url — the event
--     detail page renders it as a "Sign Up →" button.
--   * Fix the map address: the flyer says 10121 Morgan Creek Dr, Austin TX 78717;
--     the stored location_url pointed at 14100 Morgan Creek Dr (wrong street #).
-- Date/time/location name unchanged (Fri Aug 7, 5:00-8:00 PM, Morningside Pool).
--
-- Idempotent: guarded on the slug.

BEGIN;

UPDATE events SET
  signup_url = 'https://www.signupgenius.com/go/60B084CA4AC2DA6FB6-64853046-2026?useFullSite=true#/',
  location_url = 'https://maps.google.com/?q=10121+Morgan+Creek+Dr+Austin+TX+78717'
WHERE slug = 'pool-party-2026';

COMMIT;

-- ===
-- db/migrations/082_youth_camp_signup_link.sql
-- ===

-- 082_youth_camp_signup_link.sql
--
-- Youth Football Camp (Fri Jul 24 2026, slug youth-football-camp-2026,
-- "7th-9th Grade Football Camp") registration link.
--   * Add the camp registration Google Form as signup_url — the event detail
--     page renders it as a "Sign Up →" button.
--   * The booster supplied the private editor link (…/edit); this stores the
--     PUBLIC responder link (…/viewform) instead, which was verified to serve
--     a fillable form with no login required.
-- Date/time/location unchanged.
--
-- Idempotent: guarded on the slug.

BEGIN;

UPDATE events SET
  signup_url = 'https://docs.google.com/forms/d/1Qno3ycvDrSzDgmySCiX0WxOJoX4G5PTz81WCX6cj_hc/viewform'
WHERE slug = 'youth-football-camp-2026';

COMMIT;

-- ===
-- db/migrations/083_pool_party_description_update.sql
-- ===

-- 083_pool_party_description_update.sql
--
-- Softens the pool party food ask (donate "if you're able" rather than
-- "asked to donate") and points readers to the event link for directions +
-- the food sign-up (the detail page's Get directions + Sign Up buttons).
--
-- Idempotent: guarded on the slug.

BEGIN;

UPDATE events SET
  description = $desc$Join us for the 2026 Mavs Football Pool Party! All teams and families are welcome, and the Mavs coaching staff and booster club will be there. The booster club provides the main dishes, and if you're able, we'd love help with drinks, desserts, fruit and veggies, sides, and chips. Click the McNeil Mavs Pool Party link for directions and to sign up to bring food. Please make sure to pick your athlete up by 8:00 PM.$desc$
WHERE slug = 'pool-party-2026';

COMMIT;

-- ===
-- db/migrations/084_resources_add_meal_program.sql
-- ===

-- 084_resources_add_meal_program.sql
--
-- Adds the "2026 Game Day Meal Program - Parent Payment Form" to /resources
-- (Forms & Links) under Registration & Forms, sort_order 4 (after RRISD Athletic
-- Forms). Uses the public /viewform responder link (NOT the /edit editor link).
-- The form is a Google Form with a payment add-on; the Stripe checkout runs
-- after submit. icon_hint='form' (ClipboardList), matching the mailing-list row.
--
-- Idempotent: INSERT-if-absent on (section, label).

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
SELECT 'registration_forms',
       'Game-Day Meal Program (Parent Payment)',
       'https://docs.google.com/forms/d/1jFCsISKk-BIBwgl-Hp-62-bZzTHKg-wqX5Fa7Q6j2JM/viewform',
       'Sign up and contribute to your athlete''s game-day meals for the 2026 season.',
       'form',
       4,
       true
WHERE NOT EXISTS (
  SELECT 1 FROM resource_links
  WHERE section = 'registration_forms' AND label = 'Game-Day Meal Program (Parent Payment)'
);

COMMIT;

-- ===
-- db/migrations/085_pool_party_attendee_signup.sql
-- ===

-- 085_pool_party_attendee_signup.sql
--
-- Swaps the pool party event's Sign Up from the food SignUpGenius to the new
-- attendee RSVP Google Form ("McNeil Mavs Football Pool Party — Sign-Up"), and
-- updates the copy from "sign up to bring food" to "sign up to attend". The
-- food SignUpGenius is still reachable via a link inside the attendee form.
-- Uses the clean /viewform link (the ?edit_requested=true param was stripped).
--
-- Idempotent: guarded on the slug.

BEGIN;

UPDATE events SET
  signup_url = 'https://docs.google.com/forms/d/12oQleUb7c3vbcd6UjoWfDPivsC0icTZ3L4tg9yq-NS4/viewform',
  description = $desc$Join us for the 2026 Mavs Football Pool Party! All teams and families are welcome, and the Mavs coaching staff and booster club will be there. The booster club provides the main dishes, and if you're able, we'd love help with drinks, desserts, fruit and veggies, sides, and chips. Click the McNeil Mavs Pool Party link for directions and to sign up to attend (there's a food sign-up in the form too). Please make sure to pick your athlete up by 8:00 PM.$desc$
WHERE slug = 'pool-party-2026';

COMMIT;

-- ===
-- db/migrations/086_sponsor_program_ad_addon.sql
-- ===

-- 086_sponsor_program_ad_addon.sql
--
-- Adds a "Program Ad" add-on to the sponsorship page with a tiered price range
-- ($100 quarter page / $150 half / $250 full) and a July 31 commit deadline.
--
-- Schema: adds price_display (nullable text). The sponsor card renders a single
-- computed "$X" price; price_display lets a row show a custom string instead
-- (here the "$100–$250" range). NULL on every existing row = unchanged behavior.
--
-- The deadline rides in badge_label ("Commit by July 31" green pill); the tier
-- breakdown is in the summary description. is_addon=true so it renders in the
-- Add-Ons section. Seeded at year 2025-26 (current_year, what the page reads).
--
-- Idempotent: column IF NOT EXISTS; INSERT-if-absent on (year, name).

BEGIN;

ALTER TABLE sponsorship_tiers ADD COLUMN IF NOT EXISTS price_display text;

INSERT INTO sponsorship_tiers (name, price_cents, description, perks, sort_order, active, year, badge_label, is_addon, price_flexible, term_label, price_display)
SELECT 'Program Ad', 10000,
  $desc$Ad in the football program

Reserve space in this season's football program: 1/4 page (logo) $100, 1/2 page $150, or full page $250. Commit by July 31 to make this season's program.$desc$,
  '[]'::jsonb, 9, true, '2025-26', 'Commit by July 31', true, false, NULL, '$100–$250'
WHERE NOT EXISTS (
  SELECT 1 FROM sponsorship_tiers WHERE year = '2025-26' AND name = 'Program Ad'
);

COMMIT;

-- ===
-- db/migrations/087_events_seed_community_night_2026.sql
-- ===

-- 087_events_seed_community_night_2026.sql
--
-- Seeds the Phil's & Amy's Community Night (profit-share fundraiser) as a
-- published event on /events. Confirmed official (Carol, 2026-07-24).
-- Tue Aug 4, 2026, 4:00-8:00 PM CDT (-05) at Phil's Ice House on US-183.
-- Same pattern as 059_events_seed_pool_party_2026.sql.
--
-- Idempotent: INSERT-if-absent on slug.

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
)
SELECT
  'Phil’s & Amy’s Community Night',
  'community-night-phils-amys-2026',
  'Join the Mavs for a Community Night at Phil’s Ice House (183) on Tuesday, August 4, 4:00–8:00 PM. Mention McNeil Football at the register and a portion of your purchase supports the team — everyone in your party counts, so bring the whole family. An easy, delicious way to fuel the season.',
  '2026-08-04 16:00:00-05'::timestamptz,
  '2026-08-04 20:00:00-05'::timestamptz,
  'Phil’s Ice House (183)',
  'https://maps.google.com/?q=13265+N+US-183+Austin+TX+78750',
  'published',
  false
WHERE NOT EXISTS (
  SELECT 1 FROM events WHERE slug = 'community-night-phils-amys-2026'
);

COMMIT;

-- ===
-- db/migrations/088_photo_shoot_jeans_only.sql
-- ===

-- 088_photo_shoot_jeans_only.sql
--
-- Senior photo shoot (7/26): coaches hand out jerseys AT the shoot (players
-- don't take them home), so "wearing jerseys and jeans" is wrong. Change to
-- jeans only + note jerseys are provided. Time (10:30 AM) unchanged.
--
-- Idempotent: targeted REPLACE, guarded on the old phrase.

BEGIN;

UPDATE events
SET description = replace(
      description,
      'wearing jerseys and jeans.',
      'wearing jeans. Jerseys will be handed out at the shoot.'
    )
WHERE slug = 'senior-photo-shoot-2026'
  AND description LIKE '%wearing jerseys and jeans.%';

COMMIT;

-- ===
-- db/migrations/089_hero_tile_community_night.sql
-- ===

-- 089_hero_tile_community_night.sql
--
-- Adds a homepage carousel tile (headline_cta) for the Phil's & Amy's Community
-- Night; its CTA links to the event info page. Same payload shape as the other
-- headline_cta tiles (headline / subhead / cta_label / cta_url; cta_url renders
-- via next/link, so an internal path works). sort_order 5 (after the 4 existing).
--
-- Time-limited: deactivate (active=false) after Aug 4 so it doesn't linger.
-- Idempotent: INSERT-if-absent on the cta_url.

BEGIN;

INSERT INTO hero_foreground_tiles (tile_type, payload, sort_order, active)
SELECT 'headline_cta',
  '{"headline":"Phil’s & Amy’s Community Night","subhead":"Tue Aug 4, 4–8 PM at Phil’s Ice House (183). Mention McNeil Football at the register.","cta_label":"Event Details","cta_url":"/events/community-night-phils-amys-2026"}'::jsonb,
  5, true
WHERE NOT EXISTS (
  SELECT 1 FROM hero_foreground_tiles
  WHERE tile_type = 'headline_cta'
    AND payload->>'cta_url' = '/events/community-night-phils-amys-2026'
);

COMMIT;

-- ===
-- db/migrations/090_events_seed_senior_program_ad.sql
-- ===

-- 090_events_seed_senior_program_ad.sql
--
-- Seeds "Reserve a Senior Program Ad" as a published event with a July 31
-- deadline, so it shows in Upcoming until then and auto-drops to Past on Aug 1.
-- Sign-up button = the senior-ad Google Form ($25 / quarter page). No physical
-- location. July is CDT (-05). Same seed pattern as 059.
--
-- Idempotent: INSERT-if-absent on slug.

BEGIN;

INSERT INTO events (
  title, slug, description, starts_at, ends_at, location, location_url, signup_url, status, featured
)
SELECT
  'Reserve a Senior Program Ad',
  'senior-program-ad-2026',
  'Feature your senior in the Spirit Book, the football program produced by the cheer boosters. Senior ads are $25 per quarter page. Reserve your spot by July 31 using the sign-up button.',
  '2026-07-31 23:59:00-05'::timestamptz,
  NULL,
  NULL,
  NULL,
  'https://docs.google.com/forms/d/e/1FAIpQLScGDI6gHk6-hyVJDBxrZAwiNpQwLDeHzjQ74Npg57nwvKjCSQ/viewform',
  'published',
  false
WHERE NOT EXISTS (
  SELECT 1 FROM events WHERE slug = 'senior-program-ad-2026'
);

COMMIT;

-- ===
-- db/migrations/091_hero_tiles_expiry.sql
-- ===

-- 091_hero_tiles_expiry.sql
--
-- Adds date-based auto-expiry to homepage carousel tiles + uses it:
--   * new column expires_at (nullable); the carousel loader hides tiles past it.
--   * Community Night tile → expires Aug 5 (event is Aug 4).
--   * new Senior Program Ads tile → links to the senior-ad event, expires Aug 1.
-- July/Aug are CDT (-05). Idempotent: column IF NOT EXISTS; guarded UPDATE/INSERT.

BEGIN;

ALTER TABLE hero_foreground_tiles ADD COLUMN IF NOT EXISTS expires_at timestamptz;

UPDATE hero_foreground_tiles
SET expires_at = '2026-08-05 00:00:00-05'::timestamptz
WHERE tile_type = 'headline_cta'
  AND payload->>'cta_url' = '/events/community-night-phils-amys-2026';

INSERT INTO hero_foreground_tiles (tile_type, payload, sort_order, active, expires_at)
SELECT 'headline_cta',
  '{"headline":"Senior Program Ads","subhead":"Feature your senior in the football program. $25 per quarter page. Reserve by July 31.","cta_label":"Reserve Now","cta_url":"/events/senior-program-ad-2026"}'::jsonb,
  6, true, '2026-08-01 00:00:00-05'::timestamptz
WHERE NOT EXISTS (
  SELECT 1 FROM hero_foreground_tiles
  WHERE tile_type = 'headline_cta'
    AND payload->>'cta_url' = '/events/senior-program-ad-2026'
);

COMMIT;

-- ===
-- db/migrations/092_fix_mavmail_url.sql
-- ===

-- 092_fix_mavmail_url.sql
--
-- The MavMail resource link pointed to a single dated newsletter issue
-- (mavmail-sunday-may-24-2026), which RRISD has since removed (HTTP 410 Gone).
-- RRISD only publishes MavMail as rotating per-issue URLs (edurooms /engage/…,
-- Smore per-issue codes) with no stable "latest" permalink, so any dated link
-- breaks weekly. Point it instead at the McNeil HS Live Feed, which always
-- surfaces the current MavMail and does not rotate. Idempotent; matched by
-- label + section.

BEGIN;

UPDATE resource_links
SET url = 'https://mcneil.roundrockisd.org/o/mcneil/live-feed'
WHERE section = 'communications'
  AND label = 'MavMail';

COMMIT;

-- ===
-- db/migrations/093_coaches_edwards_and_photos.sql
-- ===

-- 093_coaches_edwards_and_photos.sql
--
-- Adds new Defensive Line Coach Nick Edwards (2026-27) and sets head-shot photos
-- for Gillis, Matthews, and Edwards (faces cropped from their "Welcome to Mav
-- Nation" graphics, uploaded to the coach-photos storage bucket).
-- Per Jeremy (2026-07-26): the two existing "Defensive Line Coach" rows (Wallin,
-- Debose) stay; Edwards is added alongside them, no replacements. Edwards sorts
-- at 16 to group with the other DL coaches (Wallin 10, Debose 15). Idempotent.

BEGIN;

INSERT INTO coaches (year, name, role, role_category, sort_order, photo_url, active)
SELECT '2026-27', 'Nick Edwards', 'Defensive Line Coach', 'position_coach', 16,
       'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachEdwardsHead.jpg',
       true
WHERE NOT EXISTS (
  SELECT 1 FROM coaches WHERE year = '2026-27' AND name = 'Nick Edwards'
);

UPDATE coaches
SET photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachGillisHead.jpg'
WHERE year = '2026-27' AND name = 'Alexander Gillis';

UPDATE coaches
SET photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachMatthewsHead.jpg'
WHERE year = '2026-27' AND name = 'Barrett Matthews';

COMMIT;

-- ===
-- db/migrations/094_readd_rudys_sponsor.sql
-- ===

-- 094_readd_rudys_sponsor.sql
--
-- Re-adds Rudy's BBQ as an MVP-tier sponsor. Migration 060 removed it on the
-- belief it was a placeholder; Jeremy confirmed (2026-07-26) Rudy's is a real
-- sponsor. Restored exactly as migration 041 seeded it (MVP tier, sort_order 1,
-- year 2025-26). The logo object (sponsor-logos/rudys-bbq.png) is still present.
-- MVP is otherwise empty, so Rudy's renders alone at the top/largest size, which
-- also demonstrates the tier-size hierarchy to prospects. Idempotent.

BEGIN;

INSERT INTO sponsors (name, logo_url, website_url, tier_id, year, featured, sort_order, active)
SELECT 'Rudy''s BBQ', 'rudys-bbq.png', 'https://rudysbbq.com',
       'a1e5e262-ad4a-46c7-8e5b-7752bb653b23', '2025-26', false, 1, true
WHERE NOT EXISTS (
  SELECT 1 FROM sponsors WHERE name = 'Rudy''s BBQ' AND year = '2025-26'
);

COMMIT;

-- ===
-- db/migrations/095_add_current_roster_year.sql
-- ===

-- Migration 095: decouple the displayed ROSTER year from current_year, and
-- advance it to 2026-27 so the stale 2025-26 rosters stop showing.
-- Same pattern as current_board_year (030), current_coaches_year (055),
-- current_schedule_year (056).
--
-- Why not just flip current_year: it still governs sponsors, sponsorship_tiers
-- (both /sponsors and /boosters/sponsor) and the homepage sponsor strip, all
-- seeded as 2025-26. Flipping it would blank those pages.
--
-- The empty 2026-27 roster rows already exist (varsity, jv, freshman Blue +
-- Green; 0 players, no pdf_storage_path), so the roster pages render their
-- "Coming Soon" empty state and the Print View buttons drop off on their own.
-- The 2025-26 rosters + players are left intact as history, just unreachable.
-- When the real 2026-27 rosters arrive, seed players into those rows -- no
-- flag flip and no code change needed.
BEGIN;
ALTER TABLE site_settings
  ADD COLUMN IF NOT EXISTS current_roster_year text NOT NULL DEFAULT '2025-26';
UPDATE site_settings SET current_roster_year = '2026-27' WHERE id = 1;
COMMIT;

-- ===
-- db/migrations/096_rename_senior_program_ad_to_shoutout.sql
-- ===

-- 096_rename_senior_program_ad_to_shoutout.sql
--
-- Renames the senior Spirit Book item from "Senior Program Ad(s)" to
-- "Senior Shoutout(s)" so parents don't read it as a paid business ad
-- (board ask, 2026-07-28). Touches display copy only:
--   * hero_foreground_tiles headline "Senior Program Ads" -> "Senior Shoutouts"
--   * events.title "Reserve a Senior Program Ad" -> "Reserve a Senior Shoutout"
--   * events.description "Senior ads are $25..." -> "Senior shoutouts are $25..."
--
-- The slug stays 'senior-program-ad-2026' on purpose: it is the hero tile's
-- cta_url and may already be shared in Facebook posts / the newsletter.
-- The *sponsorship* "Program Ad" add-on (mig 086) is a real business ad and is
-- deliberately NOT renamed.
--
-- Idempotent: matched on the tile cta_url / event slug, re-runnable.

BEGIN;

UPDATE hero_foreground_tiles
SET payload = jsonb_set(payload, '{headline}', '"Senior Shoutouts"'::jsonb)
WHERE tile_type = 'headline_cta'
  AND payload->>'cta_url' = '/events/senior-program-ad-2026';

UPDATE events
SET title = 'Reserve a Senior Shoutout',
    description = 'Feature your senior in the Spirit Book, the football program produced by the cheer boosters. Senior shoutouts are $25 per quarter page. Reserve your spot by July 31 using the sign-up button.'
WHERE slug = 'senior-program-ad-2026';

COMMIT;

-- ===
-- db/migrations/097_resources_add_one_mav_parent_meeting_deck.sql
-- ===

-- 097_resources_add_one_mav_parent_meeting_deck.sql
--
-- Adds Coach Gardner's ONE MAV Parent & Athlete Meeting presentation (the
-- 7/27/2026 season-kickoff deck, 18 slides) to /resources (Forms & Links)
-- under the "Resources" section at sort_order 0, i.e. ABOVE "McNeil High
-- School" (1) and "HUDL" (2) — it's the most timely item on the page for the
-- next few weeks.
--
-- Jeremy 2026-07-28, at Coach Gardner's request ("could you post the
-- presentation from last night"). Coach will point parents at the Forms &
-- Links page from SportsYou, so NO homepage link/announcement by design.
--
-- PDF lives in the public `documents` bucket, following the existing
-- rosters/ + schedules/ + sponsorship/ convention:
--   documents/meetings/one-mav-parent-athlete-meeting-2026-07-27.pdf
-- No `?download=` param (unlike the sponsorship letter) — a presentation
-- should open in a tab, not download.
--
-- DELIBERATE: the label is date-stamped and the description says nothing
-- about practice/game dates or registration systems. The deck embeds an
-- August practice calendar (a photo of a printed sheet, two scrimmages still
-- TBD) and the 2026 varsity schedule marked "subject to change" — /schedule
-- remains the live source of truth. Do not relabel this row as a schedule
-- link, and do not let it become the schedule link parents bookmark.
--
-- NOTE (unresolved as of this migration): deck slide 9 instructs parents to
-- complete paperwork in **RankOne.com** and requires GREEN status before
-- Aug 3, but the `registration_forms` row "Aktivate (Athletic Registration)"
-- says Aktivate "replaces the old RankOne system." One of the two is stale.
-- Flagged to Jeremy to confirm with Coach Gardner; this migration takes no
-- position on it either way.

BEGIN;

INSERT INTO resource_links (section, label, url, description, icon_hint, sort_order, active)
VALUES (
  'resources',
  'ONE MAV Parent & Athlete Meeting (July 27, 2026)',
  'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/documents/meetings/one-mav-parent-athlete-meeting-2026-07-27.pdf',
  'Coach Gardner''s presentation from the parent meeting: program standards, academics, safety protocols, and parent expectations.',
  'pdf',
  0,
  true
);

COMMIT;

-- ===
-- db/migrations/098_resources_retire_aktivate_promote_rankone.sql
-- ===

-- 098_resources_retire_aktivate_promote_rankone.sql
--
-- Fixes the RankOne-vs-Aktivate contradiction surfaced 2026-07-28 when Coach
-- Gardner's ONE MAV deck was posted (migration 097). Deck slide 9 sends
-- parents to RankOne.com and requires GREEN status before Aug 3, while
-- /resources still told them Aktivate had "replaced the old RankOne system."
--
-- WHY AKTIVATE IS THE STALE ONE (traced, not guessed):
--   * The Aktivate row came from migration 018 — the ORIGINAL SportsEngine
--     content port (May 2026). It was seeded from old-site copy and never
--     revisited.
--   * Migration 035 (2026-05-19) already repointed "RRISD Athletic Forms" to
--     https://roundrockisd.rankone.com/New/NewInstructionsPage.aspx because
--     Jeremy confirmed Rank One was the real forms portal.
--   * Migration 071 (July 2026 events) embeds that same Rank One link for both
--     equipment pickups, with the "all green" requirement.
--   * Coach's 7/27/2026 deck says Rank One, and Jeremy + Karen confirmed from
--     what they're actually seeing as parents in 2026-27.
-- So two of three site surfaces plus the coaching staff all say Rank One. The
-- Aktivate row was the only holdout.
--
-- WHAT THIS DOES:
--   1. Deactivates the Aktivate row (active=false rather than DELETE, so the
--      history stays visible and the rollback is trivial). If RRISD ever does
--      move to Aktivate, flip it back rather than reseeding.
--   2. Promotes the existing (already-correct-URL) "RRISD Athletic Forms" row
--      into the vacated top slot (sort_order 3 → 1) and relabels it
--      "RRISD Athletic Forms (Rank One)" so parents arriving from Coach's deck
--      recognize the name he used.
--   3. Rewrites its description to carry the actual requirement — forms
--      complete and GREEN before an athlete can practice or be issued
--      equipment — which is the single most actionable line in the deck.
--
-- Deliberately NOT creating a second row for Rank One: the RRISD Athletic
-- Forms row already points at the exact same URL, and two entries to one
-- destination is how parents get confused. One row, one destination.
--
-- No date (Aug 3) in the description on purpose — /events + /schedule carry
-- dates; this row states the standing requirement so it doesn't go stale.

BEGIN;

-- 1. Retire the stale Aktivate row.
UPDATE resource_links
SET active = false
WHERE section = 'registration_forms'
  AND label = 'Aktivate (Athletic Registration)';

-- 2 + 3. Promote, relabel, and rewrite the Rank One row.
UPDATE resource_links
SET label = 'RRISD Athletic Forms (Rank One)',
    description = 'Complete every required athletic form in Rank One. Athletes must be "all green" before they can practice, compete, or be issued equipment.',
    sort_order = 1
WHERE section = 'registration_forms'
  AND label = 'RRISD Athletic Forms';

COMMIT;

-- ===
-- db/migrations/099_resources_retire_uil_forms.sql
-- ===

-- 099_resources_retire_uil_forms.sql
--
-- Retires the "UIL Forms" row on /resources (Forms & Links → Registration &
-- Forms). Jeremy 2026-07-28: not needed either — everything an athlete has to
-- sign is handled inside the Rank One packet, so a separate link to
-- uiltexas.org/athletics/forms sends parents to a generic state-level page
-- they have no reason to touch.
--
-- Same pattern as migration 098's Aktivate retirement: active=false, not
-- DELETE, so this is one flag flip to restore.
--
-- Registration & Forms is left with two active rows:
--   1  RRISD Athletic Forms (Rank One)
--   4  Game-Day Meal Program (Parent Payment)
-- Gap in sort_order values is harmless (the page orders by sort_order, it
-- doesn't require them to be contiguous), and leaving 4 alone keeps this
-- migration to a single field change.

BEGIN;

UPDATE resource_links
SET active = false
WHERE section = 'registration_forms'
  AND label = 'UIL Forms';

COMMIT;

-- ===
-- db/migrations/100_coaches_align_titles_with_deck.sql
-- ===

-- 100_coaches_align_titles_with_deck.sql
--
-- Aligns 2026-27 coach titles/positions with Coach Gardner's ONE MAV Parent &
-- Athlete Meeting deck (7/27/2026, slide 2). Jeremy 2026-07-28: "update titles
-- and positions per the deck — feels like coach would be more correct than us."
-- The coaching staff is the coaching staff's own source of truth.
--
-- FIRST 100-NUMBERED MIGRATION. The documented `db/apply_all.sql` regeneration
-- loop globbed `db/migrations/0*.sql`, which does NOT match `100_*.sql` — this
-- file would have silently dropped out of the bundle with no error. The glob is
-- corrected to `db/migrations/[0-9]*.sql` in docs/CLAUDE.md in the same commit.
--
-- THREE CHANGES (the other 8 coaches already matched the deck):
--
-- 1. Jerry Gardner: "Head Coach and Athletic Director"
--                -> "Athletic Coordinator / Head Football Coach"
--    Our row had him as Athletic DIRECTOR, which is Jeff Cheatham's job — the
--    deck's Administration column lists Cheatham as AD and Gardner as Athletic
--    Coordinator. Using the deck's own slide-1 expansion of "AC" rather than
--    publishing the abbreviation.
--
-- 2. Douglas Wallin: "Defensive Line Coach" -> "Linebackers Coach"
--    A real POSITION change, not wording. Migration 093 had him as the third
--    DL coach alongside Debose + Edwards; the deck moves him to linebackers,
--    leaving Debose + Edwards on the line. This is the change most worth
--    getting right — it was wrong on a public page.
--
-- 3. Barrett Matthews: "Special Teams & Pass Game Coordinator"
--                   -> "Special Teams Coordinator / Receivers"
--
-- STYLE: the deck lists bare position rooms ("Linebackers", "Running Backs");
-- the site's house style suffixes them with "Coach" ("Running Backs Coach") and
-- all 8 unchanged rows already read that way. Kept the suffix so this migration
-- changes substance, not typography. Coordinator titles are taken verbatim.
--
-- NOT CHANGED, ON PURPOSE:
--   * "Michael Hale" (deck says "Jake Hale"). A first name is neither a title
--     nor a position, and this repo has precedent for preferring full names
--     over what a document says — migration 039 deliberately set "Douglas
--     Wallin" where everything else said "Doug". Michael is plausibly legal
--     with Jake as the known-as. Awaiting Coach Gardner's answer; tracked in
--     followups.md. Same reason "Doug Wallin" stays "Douglas Wallin" here.
--   * sort_order. Wallin stays at 10, so on /coaches he now renders between
--     Matthews (6) and the two DL coaches (15, 16) — linebackers before
--     defensive line. Harmless; regroup later if the ordering ever matters.

BEGIN;

UPDATE coaches
SET role = 'Athletic Coordinator / Head Football Coach'
WHERE year = '2026-27' AND name = 'Jerry Gardner';

UPDATE coaches
SET role = 'Linebackers Coach'
WHERE year = '2026-27' AND name = 'Douglas Wallin';

UPDATE coaches
SET role = 'Special Teams Coordinator / Receivers'
WHERE year = '2026-27' AND name = 'Barrett Matthews';

COMMIT;

-- ===
-- db/migrations/101_practice_week1_from_coach.sql
-- ===

-- 101_practice_week1_from_coach.sql
--
-- Coach's "MAV FOOTBALL WEEKLY SCHEDULE, August 3-9, 2026" doc (received
-- 2026-07-31) is authoritative for week 1. It CONFLICTS with the migration-077
-- preseason seed in three places, so this is a correction, not just an add:
--
--   Tue Aug 4 upperclassmen : was 6:00-9:30  -> 5:40 arrival / 5:55 field / 7:45 end
--   Tue Aug 4 freshmen      : was 8:30-10:30 AM (or 6:30-8:30 PM) -> evening ONLY
--   Sat Aug 8 scrimmages    : was V/JV 7:30-9:30 + F 9:00-10:30
--                             -> V/JV 7:30-8:30 + F 9:00-10:00
--
-- Week 1 gains arrival-vs-on-field times, Monday equipment pickup, and Sunday
-- Aug 9 as an explicit off day. Everything after Aug 9 is unchanged from 077
-- but now sits under a "tentative" heading per Jeremy.
--
-- Varsity and JV share identical bodies (Coach's doc addresses them jointly as
-- UPPERCLASSMEN (SOPH / JR / SR)), matching the 077 convention.

begin;

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 1 — August 3–9

| Day | Arrival | On field | Ends | Notes |
|---|---|---|---|---|
| Mon Aug 3 | 7:10 a.m. | 7:30 a.m. | 11:00 a.m. | Equipment pickup 6:45 a.m. for players who still need it |
| Tue Aug 4 | 5:40 a.m. | 5:55 a.m. | 7:45 a.m. | |
| Wed Aug 5 | 7:15 a.m. | 7:30 a.m. | 11:00 a.m. | |
| Thu Aug 6 | 7:15 a.m. | 7:30 a.m. | 11:00 a.m. | |
| Fri Aug 7 | 7:15 a.m. | 7:30 a.m. | 11:00 a.m. | Pool party 5:00–8:00 p.m. at Avery Ranch |
| Sat Aug 8 | 6:45 a.m. | 7:00 a.m. | 8:30 a.m. | Upperclassmen intra-squad scrimmage 7:30–8:30 a.m. |
| Sun Aug 9 | Off day | Off day | Off day | Recover, reset and prepare |

## After Week 1 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
| Mon Aug 10 | 6:30–10:00 | |
| Tue Aug 11 | 6:30–10:00 | |
| Wed Aug 12 | 6:30–10:00 | |
| Thu Aug 13 | See Games | Scrimmage vs Hendrickson (home) |
| Fri Aug 14 | 7:00–10:00 | |
| Sat Aug 15 | 9:00–11:00 | |
| Mon Aug 17 | 6:30–10:00 | |
| Tue Aug 18 | 6:30–10:00 | |
| Wed Aug 19 | 6:20–8:15 | First day of school |
| Thu Aug 20 | See Games | Scrimmage vs Eastview (home), time TBD |
| Fri Aug 21 | 7:00–8:00 | Picture day |
| Mon Aug 24 | 6:00–8:15 | |
| Tue Aug 25 | 6:00–8:15 | |
| Wed Aug 26 | 6:20–8:15 | |
| Thu Aug 27 | 7:50–8:30 | |
| Fri Aug 28 | See Games | Game 1 at Bowie (away) |
$body$
where year = '2026-27'
  and team_level in ('varsity', 'jv');

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time.

## Week 1 — August 3–9

| Day | Arrival | On field | Ends | Notes |
|---|---|---|---|---|
| Mon Aug 3 | — | 10:00 a.m. | 12:00 p.m. | Equipment pickup 9:20 a.m. for players who still need it |
| Tue Aug 4 | 6:30 p.m. | 6:45 p.m. | 8:15 p.m. | Evening practice |
| Wed Aug 5 | 9:45 a.m. | 10:00 a.m. | 12:00 p.m. | |
| Thu Aug 6 | 9:45 a.m. | 10:00 a.m. | 12:00 p.m. | |
| Fri Aug 7 | 9:45 a.m. | 10:00 a.m. | 12:00 p.m. | Pool party 5:00–8:00 p.m. at Avery Ranch |
| Sat Aug 8 | 8:30 a.m. | 8:45 a.m. | 10:00 a.m. | Freshman intra-squad scrimmage 9:00–10:00 a.m. |
| Sun Aug 9 | Off day | Off day | Off day | Recover, reset and prepare |

## After Week 1 — tentative

**Everything below is tentative and subject to change.** See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
| Mon Aug 10 | 9:00–11:00 | |
| Tue Aug 11 | 9:00–11:00 | |
| Wed Aug 12 | 9:00–11:00 (or 6:30–8:30 PM) | |
| Thu Aug 13 | See Games | Scrimmage vs Hendrickson (home) |
| Fri Aug 14 | 9:00–11:00 | |
| Sat Aug 15 | No practice | |
| Mon Aug 17 | 9:00–11:00 | |
| Tue Aug 18 | 9:00–11:00 | |
| Wed Aug 19 | 8:10–9:45 | First day of school |
| Thu Aug 20 | See Games | Scrimmage vs Eastview (home), time TBD |
| Fri Aug 21 | 8:00–10:15 | Picture day |
| Mon Aug 24 | 8:10–9:50 | |
| Tue Aug 25 | 8:10–9:50 | |
| Wed Aug 26 | 8:10–9:50 | |
| Thu Aug 27 | 8:45–9:50 | |
| Fri Aug 28 | 8:30–9:50 | Game 1 at Bowie (away) |
$body$
where year = '2026-27'
  and team_level = 'freshman';

commit;

-- ===
-- db/migrations/102_events_week1_scrimmages_equipment.sql
-- ===

-- 102_events_week1_scrimmages_equipment.sql
--
-- Surfaces the week-1 items from Coach's Aug 3-9 doc on /events. The Pool Party
-- (Aug 7) is already seeded by migration 059; these are the three that were
-- only visible on the practice pages.
--
-- One equipment-pickup row, not two: unlike the 7/29 and 7/30 pickups seeded by
-- migration 071 (different days, different groups), both groups collect on the
-- same morning, so two same-day rows for one activity would just read as
-- duplicates. Both times are in the description.
--
-- ends_at is NULL on the pickup: Coach's doc gives designated start times
-- (6:45 a.m. / 9:20 a.m.) with no stated close, and the senior-photo-shoot row
-- from migration 070 sets the same precedent. Not inventing an end time.
--
-- August 2026 is CDT, hence the -05 offsets.

begin;

insert into events (title, slug, description, starts_at, ends_at, location, status)
values
  (
    'Equipment Pickup - Players Who Still Need Equipment',
    'equipment-pickup-aug-3-2026',
    'For players who still need to be issued equipment before the first week of practice. Upperclassmen (Soph / Jr / Sr) at 6:45 a.m., ahead of the 7:10 a.m. arrival time. Freshmen at 9:20 a.m., ahead of the 10:00 a.m. warm-up. Players already issued equipment do not need to come early.',
    '2026-08-03 06:45:00-05',
    null,
    'McNeil High School',
    'published'
  ),
  (
    'Upperclassmen Intra-Squad Scrimmage',
    'upperclassmen-intra-squad-scrimmage-2026',
    'Soph / Jr / Sr intra-squad scrimmage closing out week 1. Arrival 6:45 a.m., warm-up begins on the field at 7:00 a.m., scrimmage 7:30-8:30 a.m. The freshman scrimmage follows at 9:00 a.m.',
    '2026-08-08 07:30:00-05',
    '2026-08-08 08:30:00-05',
    'McNeil High School',
    'published'
  ),
  (
    'Freshman Intra-Squad Scrimmage',
    'freshman-intra-squad-scrimmage-2026',
    'Freshman intra-squad scrimmage closing out week 1. Arrival 8:30 a.m., warm-up begins on the field at 8:45 a.m., scrimmage 9:00-10:00 a.m. The upperclassmen scrimmage runs earlier the same morning at 7:30 a.m.',
    '2026-08-08 09:00:00-05',
    '2026-08-08 10:00:00-05',
    'McNeil High School',
    'published'
  )
on conflict (slug) do nothing;

commit;

-- ===
-- db/migrations/103_practice_week1_readable.sql
-- ===

-- 103_practice_week1_readable.sql
--
-- Reformat only. NO time changes -- every time here is byte-identical to what
-- migration 101 put in from Coach's Aug 3-9 doc.
--
-- 101 rendered week 1 as a 5-column table (Day / Arrival / On field / Ends /
-- Notes). On a 390px phone that is unreadable: "Mon Aug 3" wraps to three
-- lines, every "7:10 a.m." wraps to two, the "On field" header stacks, and the
-- Sunday row reads "Off day | Off day | Off day". Verified by screenshot.
--
-- Week 1 is now one block per day with a time-led bullet list, which is how
-- Coach's own doc reads down each cell. No columns, so nothing wraps at any
-- width, and a parent scans to the day they want.
--
-- The "After Week 1 -- tentative" half is carried over verbatim from 101: its
-- 3-column table renders fine and was not what Jeremy flagged.
--
-- DB-only, like 101 -- /schedule/practice/* reads at request time, no deploy.

begin;

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 1 — August 3–9

### Monday, Aug 3
- **6:45 a.m.** — Equipment pickup, for players who still need equipment
- **7:10 a.m.** — Arrival
- **7:30 a.m.** — Warm-up lines begin on the field
- **11:00 a.m.** — Practice ends

### Tuesday, Aug 4 — early start
- **5:40 a.m.** — Arrival
- **5:55 a.m.** — Warm-up begins on the field
- **7:45 a.m.** — Practice ends

### Wednesday, Aug 5
- **7:15 a.m.** — Arrival
- **7:30 a.m.** — Warm-up lines begin on the field
- **11:00 a.m.** — Practice ends

### Thursday, Aug 6
- **7:15 a.m.** — Arrival
- **7:30 a.m.** — Warm-up lines begin on the field
- **11:00 a.m.** — Practice ends

### Friday, Aug 7
- **7:15 a.m.** — Arrival
- **7:30 a.m.** — Warm-up lines begin on the field
- **11:00 a.m.** — Practice ends
- **5:00–8:00 p.m.** — Pool party at Avery Ranch

### Saturday, Aug 8
- **6:45 a.m.** — Arrival
- **7:00 a.m.** — Warm-up begins on the field
- **7:30–8:30 a.m.** — Upperclassmen intra-squad scrimmage

### Sunday, Aug 9
Off day. Recover, reset and prepare.

## After Week 1 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
| Mon Aug 10 | 6:30–10:00 | |
| Tue Aug 11 | 6:30–10:00 | |
| Wed Aug 12 | 6:30–10:00 | |
| Thu Aug 13 | See Games | Scrimmage vs Hendrickson (home) |
| Fri Aug 14 | 7:00–10:00 | |
| Sat Aug 15 | 9:00–11:00 | |
| Mon Aug 17 | 6:30–10:00 | |
| Tue Aug 18 | 6:30–10:00 | |
| Wed Aug 19 | 6:20–8:15 | First day of school |
| Thu Aug 20 | See Games | Scrimmage vs Eastview (home), time TBD |
| Fri Aug 21 | 7:00–8:00 | Picture day |
| Mon Aug 24 | 6:00–8:15 | |
| Tue Aug 25 | 6:00–8:15 | |
| Wed Aug 26 | 6:20–8:15 | |
| Thu Aug 27 | 7:50–8:30 | |
| Fri Aug 28 | See Games | Game 1 at Bowie (away) |$body$
where year = '2026-27'
  and team_level in ('varsity', 'jv');

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time.

## Week 1 — August 3–9

### Monday, Aug 3
- **9:20 a.m.** — Equipment pickup, for players who still need equipment
- **10:00 a.m.** — Warm-up lines begin on the field
- **12:00 p.m.** — Practice ends

### Tuesday, Aug 4 — evening practice
- **6:30 p.m.** — Arrival
- **6:45 p.m.** — Practice begins on the field
- **8:15 p.m.** — Practice ends

### Wednesday, Aug 5
- **9:45 a.m.** — Arrival
- **10:00 a.m.** — Practice begins on the field
- **12:00 p.m.** — Practice ends

### Thursday, Aug 6
- **9:45 a.m.** — Arrival
- **10:00 a.m.** — Practice begins on the field
- **12:00 p.m.** — Practice ends

### Friday, Aug 7
- **9:45 a.m.** — Arrival
- **10:00 a.m.** — Practice begins on the field
- **12:00 p.m.** — Practice ends
- **5:00–8:00 p.m.** — Pool party at Avery Ranch

### Saturday, Aug 8
- **8:30 a.m.** — Arrival
- **8:45 a.m.** — Warm-up begins on the field
- **9:00–10:00 a.m.** — Freshman intra-squad scrimmage

### Sunday, Aug 9
Off day. Recover, reset and prepare.

## After Week 1 — tentative

**Everything below is tentative and subject to change.** See the Games schedule for scrimmages and Game 1.

| Date | Practice | Notes |
|---|---|---|
| Mon Aug 10 | 9:00–11:00 | |
| Tue Aug 11 | 9:00–11:00 | |
| Wed Aug 12 | 9:00–11:00 (or 6:30–8:30 PM) | |
| Thu Aug 13 | See Games | Scrimmage vs Hendrickson (home) |
| Fri Aug 14 | 9:00–11:00 | |
| Sat Aug 15 | No practice | |
| Mon Aug 17 | 9:00–11:00 | |
| Tue Aug 18 | 9:00–11:00 | |
| Wed Aug 19 | 8:10–9:45 | First day of school |
| Thu Aug 20 | See Games | Scrimmage vs Eastview (home), time TBD |
| Fri Aug 21 | 8:00–10:15 | Picture day |
| Mon Aug 24 | 8:10–9:50 | |
| Tue Aug 25 | 8:10–9:50 | |
| Wed Aug 26 | 8:10–9:50 | |
| Thu Aug 27 | 8:45–9:50 | |
| Fri Aug 28 | 8:30–9:50 | Game 1 at Bowie (away) |$body$
where year = '2026-27'
  and team_level = 'freshman';

commit;

-- ===
-- db/migrations/104_practice_tentative_readable.sql
-- ===

-- 104_practice_tentative_readable.sql
--
-- Reformat only, second half of the same fix as 103. NO time changes: the
-- tentative-half time set is asserted identical, and week 1 is untouched.
--
-- The "After Week 1" 3-column table had the same phone problem 103 fixed
-- above it -- at 390px "Mon Aug 10" wrapped to two lines and the See-Games
-- rows collapsed into unreadable mash ("Thu AugSee Games"). Converted to a
-- one-line-per-date bullet list, generated by parsing the existing table
-- rather than retyping any time by hand.
--
-- DB-only, no deploy.

begin;

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 1 — August 3–9

### Monday, Aug 3
- **6:45 a.m.** — Equipment pickup, for players who still need equipment
- **7:10 a.m.** — Arrival
- **7:30 a.m.** — Warm-up lines begin on the field
- **11:00 a.m.** — Practice ends

### Tuesday, Aug 4 — early start
- **5:40 a.m.** — Arrival
- **5:55 a.m.** — Warm-up begins on the field
- **7:45 a.m.** — Practice ends

### Wednesday, Aug 5
- **7:15 a.m.** — Arrival
- **7:30 a.m.** — Warm-up lines begin on the field
- **11:00 a.m.** — Practice ends

### Thursday, Aug 6
- **7:15 a.m.** — Arrival
- **7:30 a.m.** — Warm-up lines begin on the field
- **11:00 a.m.** — Practice ends

### Friday, Aug 7
- **7:15 a.m.** — Arrival
- **7:30 a.m.** — Warm-up lines begin on the field
- **11:00 a.m.** — Practice ends
- **5:00–8:00 p.m.** — Pool party at Avery Ranch

### Saturday, Aug 8
- **6:45 a.m.** — Arrival
- **7:00 a.m.** — Warm-up begins on the field
- **7:30–8:30 a.m.** — Upperclassmen intra-squad scrimmage

### Sunday, Aug 9
Off day. Recover, reset and prepare.

## After Week 1 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

- **Mon Aug 10** — 6:30–10:00
- **Tue Aug 11** — 6:30–10:00
- **Wed Aug 12** — 6:30–10:00
- **Thu Aug 13** — See Games: scrimmage vs Hendrickson (home)
- **Fri Aug 14** — 7:00–10:00
- **Sat Aug 15** — 9:00–11:00
- **Mon Aug 17** — 6:30–10:00
- **Tue Aug 18** — 6:30–10:00
- **Wed Aug 19** — 6:20–8:15 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 7:00–8:00 · Picture day
- **Mon Aug 24** — 6:00–8:15
- **Tue Aug 25** — 6:00–8:15
- **Wed Aug 26** — 6:20–8:15
- **Thu Aug 27** — 7:50–8:30
- **Fri Aug 28** — See Games: game 1 at Bowie (away)
$body$
where year = '2026-27'
  and team_level in ('varsity', 'jv');

update practice_schedules
set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time.

## Week 1 — August 3–9

### Monday, Aug 3
- **9:20 a.m.** — Equipment pickup, for players who still need equipment
- **10:00 a.m.** — Warm-up lines begin on the field
- **12:00 p.m.** — Practice ends

### Tuesday, Aug 4 — evening practice
- **6:30 p.m.** — Arrival
- **6:45 p.m.** — Practice begins on the field
- **8:15 p.m.** — Practice ends

### Wednesday, Aug 5
- **9:45 a.m.** — Arrival
- **10:00 a.m.** — Practice begins on the field
- **12:00 p.m.** — Practice ends

### Thursday, Aug 6
- **9:45 a.m.** — Arrival
- **10:00 a.m.** — Practice begins on the field
- **12:00 p.m.** — Practice ends

### Friday, Aug 7
- **9:45 a.m.** — Arrival
- **10:00 a.m.** — Practice begins on the field
- **12:00 p.m.** — Practice ends
- **5:00–8:00 p.m.** — Pool party at Avery Ranch

### Saturday, Aug 8
- **8:30 a.m.** — Arrival
- **8:45 a.m.** — Warm-up begins on the field
- **9:00–10:00 a.m.** — Freshman intra-squad scrimmage

### Sunday, Aug 9
Off day. Recover, reset and prepare.

## After Week 1 — tentative

**Everything below is tentative and subject to change.** See the Games schedule for scrimmages and Game 1.

- **Mon Aug 10** — 9:00–11:00
- **Tue Aug 11** — 9:00–11:00
- **Wed Aug 12** — 9:00–11:00 (or 6:30–8:30 PM)
- **Thu Aug 13** — See Games: scrimmage vs Hendrickson (home)
- **Fri Aug 14** — 9:00–11:00
- **Sat Aug 15** — No practice
- **Mon Aug 17** — 9:00–11:00
- **Tue Aug 18** — 9:00–11:00
- **Wed Aug 19** — 8:10–9:45 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 8:00–10:15 · Picture day
- **Mon Aug 24** — 8:10–9:50
- **Tue Aug 25** — 8:10–9:50
- **Wed Aug 26** — 8:10–9:50
- **Thu Aug 27** — 8:45–9:50
- **Fri Aug 28** — 8:30–9:50 · Game 1 at Bowie (away)
$body$
where year = '2026-27'
  and team_level = 'freshman';

commit;

-- ===
-- db/migrations/105_resources_boy_checklist.sql
-- ===

-- 105_resources_boy_checklist.sql
--
-- Posts Coach's "2026-2027 Beginning of Year Checklist" to /resources under
-- Registration & Forms, and cleans up the SportsYou row.
--
-- The PDF was edited before upload (source: ~/Downloads, edited copy kept at
-- MavericksWebsite/boy_checklist/boy-checklist-2026-27.pdf):
--   1. "Code: EBQA-WNBB" REMOVED and replaced with "Email
--      contact@mcneilmavericks.org for the team code." The SportsYou join code
--      is a credential for the channel Coach uses to message families; posting
--      it on a public page hands that channel to anyone who finds the page and
--      cannot be un-published once indexed. Gated behind a human instead.
--   2. The "Sponsorship Letter" link was a raw Supabase storage URL
--      (project ref + bucket path baked into a parent-facing doc, breaks
--      silently if the file is ever re-uploaded) -> now /boosters/sponsor.
--   3. The Instagram link's share-sheet tracking params were stripped.
--   4. A mailto: annotation + underline was added on the new email address so
--      it matches the other links in the doc.
-- All 8 original link annotations were preserved (verified by rebuilding the
-- link set from the captured rects), plus the new mailto = 9 total.
--
-- sort_order 0 puts it above RRISD Athletic Forms (1): the checklist is the
-- "start here" doc that points at everything else, including Rank One.
--
-- No ?download= param, matching the ONE MAV deck (migration 097): a checklist
-- should open in a tab, and parents who want it can still print or save.
--
-- The label is year-stamped so it visibly ages. The description deliberately
-- carries no dates.

begin;

insert into resource_links (section, sort_order, label, url, description, icon_hint, active)
values (
  'registration_forms',
  0,
  '2026-27 Beginning of Year Checklist',
  'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/documents/checklists/boy-checklist-2026-27.pdf',
  'Everything to take care of before the season starts, from Coach Gardner. Every item links straight to the sign-up, form, or page you need.',
  'pdf',
  true
);

-- The live SportsYou description referenced "the SE capture" -- our internal
-- name for the SportsEngine scrape doc. It has been public since migration 064
-- and means nothing to a parent. Rewritten, and pointed at contact@ so it
-- matches the instruction now printed in the checklist PDF (both aliases are
-- Google Groups delivering to the booster Gmail, so this is wording, not
-- routing).
update resource_links
set description = 'Team messaging app for parents and players. Email contact@mcneilmavericks.org for the team code.'
where section = 'communications'
  and label = 'SportsYou (Team Messaging)';

commit;

-- ===
-- db/migrations/106_sponsors_2026_27.sql
-- ===

-- 106_sponsors_2026_27.sql
--
-- Advances the sponsor surfaces to the 2026-27 season.
--
-- WHY FLIPPING current_year IS SAFE NOW: after the coaches (055), schedule
-- (056), practice (077) and roster (095) decouplings, `current_year` governs
-- ONLY sponsors + sponsorship_tiers. Verified before writing this: the only
-- code destructuring the real `current_year` is app/page.tsx (sponsor strip +
-- MVP tier lookup), app/sponsors/page.tsx and app/boosters/sponsor/page.tsx.
-- The schedule and roster pages destructure their own year and alias it to a
-- local named `current_year`, which is why a naive grep looks alarming.
--
-- The 2025-26 sponsors and tiers are LEFT IN PLACE, not deleted. Flipping the
-- year makes them invisible on every public surface, which is what "remove the
-- old ones" needs, while keeping last season's showcase recoverable. Rolling
-- 106 back restores the 2025-26 lineup exactly.
--
-- Dropped from the public site by this migration (2025-26 only, rows retained):
-- AutoNation Chevrolet West Austin, Sunflower Bank, Dave's Ultimate
-- Automotive, TKO Heating and Air.
--
-- Carried forward: Rudy's BBQ (MVP, per Jeremy "leave Rudy's at top level for
-- now"), Luv Braces (Gold -> Blue) and Laurie Flood (Gold -> Gold), both
-- reusing their existing logo objects.
--
-- New logos uploaded to the sponsor-logos bucket:
--   mama-bettys-tex-mex.png       rasterized from the supplied SVG at 1200px
--                                 wide with a transparent background -- the
--                                 bucket only allows png/jpeg/webp, so the SVG
--                                 could not be uploaded as-is. Rendered through
--                                 headless Chrome so the navy->maroon gradient
--                                 survives.
--   north-austin-oral-surgery.png the colored (teal + navy) mark, converted
--                                 from palette to RGBA. Chosen over the
--                                 all-navy variant as it is brand-accurate.
--   capstone-acquisitions.png     converted from webp. White background kept
--                                 deliberately: the "C" is white-on-red, so
--                                 keying out white would eat part of the mark.
--                                 Invisible against the white page.
--
-- website_url is NULL for Capstone Acquisitions and Mama Betty's -- no verified
-- URL. capstoneacquisitions.com resolves but serves an empty 114-byte page, and
-- no Mama Betty's domain resolved, so neither was linked rather than shipping a
-- wrong link on a paying sponsor. Both components render a bare logo when
-- website_url is null (checked). Add them when the real URLs are known.

begin;

-- 1. Clone the full 9-row tier ladder to 2026-27. INSERT...SELECT rather than
--    re-typing so every column (perks, badge_label, term_label, price_display,
--    is_addon, price_flexible) carries over exactly. Prices are unchanged and
--    match the levels Jeremy quoted: Blue 500, Gold 1000, Platinum 1500,
--    Diamond 2500, MVP 5000.
insert into sponsorship_tiers
  (name, price_cents, description, perks, sort_order, active, year,
   badge_label, is_addon, price_flexible, term_label, price_display)
select
  name, price_cents, description, perks, sort_order, active, '2026-27',
  badge_label, is_addon, price_flexible, term_label, price_display
from sponsorship_tiers
where year = '2025-26'
  and not exists (select 1 from sponsorship_tiers where year = '2026-27');

-- 2. The 2026-27 sponsor lineup. tier_id resolved by name against the rows just
--    created, so no hardcoded uuids.
insert into sponsors (name, logo_url, website_url, tier_id, sort_order, year, active)
select v.name, v.logo_url, v.website_url, t.id, v.sort_order, '2026-27', true
from (values
  ('Rudy''s BBQ',                  'rudys-bbq.png',                 'https://rudysbbq.com',                  'MVP',      1),
  ('Capstone Acquisitions',        'capstone-acquisitions.png',     null,                                    'Platinum', 2),
  ('North Austin Oral Surgery',    'north-austin-oral-surgery.png', 'https://northaustinoralsurgery.com',    'Platinum', 3),
  ('Laurie Flood Real Estate Team','laurie-flood-realtor.png',      'https://austintexasbestrealestate.com', 'Gold',     4),
  ('Luv Braces',                   'luv-braces.png',                'https://luvbraces.com',                 'Blue',     5),
  ('Mama Betty''s Tex-Mex',        'mama-bettys-tex-mex.png',       null,                                    'Blue',     6)
) as v(name, logo_url, website_url, tier_name, sort_order)
join sponsorship_tiers t
  on t.year = '2026-27' and t.name = v.tier_name and t.active
where not exists (
  select 1 from sponsors s where s.year = '2026-27' and s.name = v.name
);

-- 3. Point the sponsor surfaces at the new season.
update site_settings set current_year = '2026-27';

commit;

-- ===
-- db/migrations/107_sponsor_urls.sql
-- ===

-- 107_sponsor_urls.sql
--
-- Fills in the two website_url values that 106 deliberately left NULL because
-- no URL could be verified at the time. Both supplied by Jeremy and checked:
--
--   capstonecoins.com     200, "Austin Rare Coin Dealer | Ancient, U.S. Gold &
--                         Shipwreck Coins". The storefront brand is Capstone
--                         Coins rather than Capstone Acquisitions, but the site
--                         itself references "Capstone Acquisitions", so it is
--                         the same business -- not a name collision. (The
--                         earlier guess, capstoneacquisitions.com, serves an
--                         empty 114-byte page and is NOT the sponsor's site.)
--   ilovemamabettys.com   200, "Your Favorite Tex-Mex Restaurant in Austin! -
--                         Mama Betty's Tex-Mex".
--
-- Scoped to year 2026-27 so the retired 2025-26 rows are untouched.

begin;

update sponsors
set website_url = 'https://capstonecoins.com'
where year = '2026-27' and name = 'Capstone Acquisitions';

update sponsors
set website_url = 'https://ilovemamabettys.com'
where year = '2026-27' and name = 'Mama Betty''s Tex-Mex';

commit;

-- ===
-- db/migrations/108_event_meet_the_mavs_2026.sql
-- ===

-- 108_event_meet_the_mavs_2026.sql
--
-- Meet the Mavs 2026, Friday August 14. Closes the open item that has been
-- carried since 2026-07-17 ("date contested Aug 14 vs 15"); Jeremy confirmed
-- Aug 14 on 2026-08-01.
--
-- Checked before seeding: Aug 14 2026 is a Friday and nothing else is on it.
-- The Hendrickson scrimmage is the night before (Aug 13, V 7:00 / JV+F 5:30),
-- which is what booster_club_info flagged as the thing that might move this
-- event -- it does not conflict.
--
-- ⚠️ TIME AND LOCATION ARE INHERITED FROM THE 2025 EVENT (6:00-8:00 PM at
-- McNeil High School Stadium, migration 048), NOT independently confirmed for
-- 2026. Only the date came from Jeremy. events.starts_at is NOT NULL so a time
-- had to be chosen; last year's is the best available answer. Correct it if the
-- committee sets a different window.
--
-- August 2026 is CDT, hence -05.

begin;

insert into events (title, slug, description, starts_at, ends_at, location, location_url, status)
values (
  '2026 Meet the Mavs',
  'meet-the-mavs-2026',
  'Annual season-kickoff event introducing the 2026-27 Mavericks football team to the community. Player introductions, coach remarks, and food.',
  '2026-08-14 18:00:00-05',
  '2026-08-14 20:00:00-05',
  'McNeil High School Stadium',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published'
)
on conflict (slug) do nothing;

commit;

-- ===
-- db/migrations/109_board_pelosi_soto.sql
-- ===

-- 109_board_pelosi_soto.sql
--
-- 2026-27 board: add Rocco Pelosi as a second Treasurer alongside Ashley Root,
-- and fill the VP of Merchandise vacancy with Monica Soto.
--
-- Per Jeremy (2026-08-02): both are already members of their role Google Groups,
-- so email_alias points at the role address, not the shared booster Gmail.
--   * Rocco Pelosi  -> treasurer@mcneilmavericks.org   (same address as Ashley)
--   * Monica Soto   -> merchandise@mcneilmavericks.org (one of the 14 aliases)
--
-- Two decisions worth recording:
--
-- 1. Rocco is INSERTED at sort_order 4 and everything from 4 down shifts by one,
--    rather than being appended at the end. The ask was that the two Treasurer
--    cards sit next to each other; Ashley is at 3 and sort_order is an integer,
--    so there is no value between 3 and 4 to slot into. There is no unique
--    constraint on sort_order, so the shift is a single statement.
--    Chevon Williams (inactive, sort_order 2) is deliberately left where she is
--    -- she is filtered out by active=false and moving her would be noise.
--
-- 2. Sylvia Brito's vacancy row is SOFT-DELETED and Monica is a NEW row, rather
--    than renaming Sylvia's row to Monica. That row carries Sylvia's history and
--    her created_at; renaming a person's record to a different person loses one
--    and falsifies the other. active=false matches how Chevon was retired in
--    migration 061. The "Position Open" card disappears as a side effect, which
--    is the intent -- the seat is filled.
--
-- Idempotent: guarded inserts, and the sort_order shift is skipped if Rocco is
-- already present.

BEGIN;

-- 1. Make room at sort_order 4, but only on a first run.
UPDATE board_members
SET sort_order = sort_order + 1
WHERE year = '2026-27'
  AND sort_order >= 4
  AND NOT EXISTS (
    SELECT 1 FROM board_members
    WHERE year = '2026-27' AND name = 'Rocco Pelosi'
  );

-- 2. Rocco Pelosi, Treasurer, immediately after Ashley Root.
INSERT INTO board_members (name, role, email_alias, sort_order, year, active, is_vacant)
SELECT 'Rocco Pelosi', 'Treasurer', 'treasurer@mcneilmavericks.org', 4, '2026-27', true, false
WHERE NOT EXISTS (
  SELECT 1 FROM board_members WHERE year = '2026-27' AND name = 'Rocco Pelosi'
);

-- 3. Retire the VP of Merchandise vacancy placeholder.
UPDATE board_members
SET active = false
WHERE year = '2026-27'
  AND name = 'Sylvia Brito'
  AND is_vacant = true
  AND active = true;

-- 4. Monica Soto fills VP of Merchandise. Sorts where the vacancy card sat.
INSERT INTO board_members (name, role, email_alias, sort_order, year, active, is_vacant)
SELECT 'Monica Soto', 'VP of Merchandise', 'merchandise@mcneilmavericks.org', 7, '2026-27', true, false
WHERE NOT EXISTS (
  SELECT 1 FROM board_members WHERE year = '2026-27' AND name = 'Monica Soto'
);

COMMIT;

-- ===
-- db/migrations/110_coach_photos_umberger_jones.sql
-- ===

-- 110_coach_photos_umberger_jones.sql
--
-- Head-shot photos for Thomas Umberger (WR) and Devonte Jones (DB), cropped from
-- their "Welcome to Mav Nation" announcement graphics and uploaded to the
-- coach-photos bucket. Same pattern as migration 093 did for Gillis, Matthews
-- and Edwards.
--
-- Why these two were skipped in 093: their graphics did not exist locally when
-- that batch ran on 2026-07-26 (the files landed that evening, several hours
-- after the session ended). They have been carried as an open item in
-- followups.md since. Jeremy supplied both on 2026-08-02.
--
-- Ryan Doyle (OL) STILL HAS NO PHOTO -- no graphic has ever been provided. He
-- keeps the horseshoe-mark fallback and stays on the followups list.
--
-- Idempotent: plain UPDATEs matched on name + year.

BEGIN;

UPDATE coaches
SET photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachUmbergerHead.jpg'
WHERE year = '2026-27' AND name = 'Thomas Umberger';

UPDATE coaches
SET photo_url = 'https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/coach-photos/CoachJonesHead.jpg'
WHERE year = '2026-27' AND name = 'Devonte Jones';

COMMIT;

-- ===
-- db/migrations/111_rudys_deactivate_not_a_sponsor.sql
-- ===

-- 111_rudys_deactivate_not_a_sponsor.sql
--
-- Rudy's BBQ is NOT a sponsor. Jeremy confirmed 2026-08-03 after checking --
-- the logo has been on the site since the migration 041 placeholder seed, was
-- correctly removed by 060, then wrongly restored by 094 on a bad confirmation,
-- and carried into the 2026-27 lineup by 106. Ends here.
--
-- DEACTIVATE, DO NOT DELETE. Jeremy wants the row (and the logo object
-- sponsor-logos/rudys-bbq.png) held in case Rudy's does sponsor later --
-- flipping `active` back to true is then the whole job. Every public sponsor
-- query filters `.eq("active", true)` (app/page.tsx, app/sponsors/page.tsx,
-- app/boosters/sponsor/page.tsx), so active=false is equivalent to gone on the
-- site while the row survives.
--
-- Both season rows are deactivated, not just the live one. 2026-27 is what
-- current_year points at today; the 2025-26 row is only invisible because of
-- that pointer, and would resurface on any year flip back (or a 106 rollback).
-- Rudy's was never a sponsor in either season, so neither row should render.
--
-- CONSEQUENCE (same as when 060 did this): Rudy's is the only MVP-tier sponsor,
-- so after this the MVP slot is empty in 2026-27. Both surfaces guard on
-- sponsor-count > 0 per tier, so nothing breaks -- the /sponsors MVP section
-- stops rendering its h2 entirely and the homepage strip drops its top-tier
-- row, leaving the 5 remaining logos (2 Platinum, 1 Gold, 2 Blue) on row 2.
-- Side effect worth knowing: the "bigger sponsorship = bigger logo" hierarchy
-- now tops out at Platinum on the page prospects see.
--
-- Idempotent.

begin;

update sponsors
set active = false
where name = 'Rudy''s BBQ'
  and year in ('2025-26', '2026-27');

commit;

-- ===
-- db/migrations/112_sponsor_freddies_carwash.sql
-- ===

-- 112_sponsor_freddies_carwash.sql
--
-- Adds Freddie's Carwash as a Blue-tier ($500) sponsor for 2026-27. Jeremy
-- closed them 2026-08-04. Seventh sponsor of the season.
--
-- Tier: $500 maps to Blue (sponsorship_tiers 2026-27 Blue = 50000 cents),
-- confirmed against the live ladder rather than assumed. tier_id is resolved by
-- name at insert time, same pattern as migration 106, so no hardcoded uuid.
--
-- sort_order 7, appending after Mama Betty's Tex-Mex (6). Sponsors render in
-- sort_order within their tier, so this puts Freddie's last among the Blues.
--
-- website_url: https://freddiescarwash.com -- verified live (HTTP 200) before
-- writing this, per the rule set in 106 about not shipping a wrong link on a
-- paying sponsor. Real business, 2009 Wells Branch Pkwy in north Austin, which
-- is a few minutes from campus.
--
-- LOGO: sponsor-logos/freddies-carwash.png, already uploaded and verified
-- publicly readable (HTTP 200, 1200x1201 RGBA). Prep notes, because the source
-- was a 2-page 512pt Illustrator PDF and none of this is reproducible from the
-- filename alone:
--   * Both PDF pages are the same circular badge -- pixel-diffed them, max
--     channel difference 1, so page 1 was used and page 2 ignored.
--   * Rendered at 300dpi, trimmed to the artwork bbox, downscaled to 1200px
--     wide in RGB, and only THEN keyed white -> alpha, so the anti-aliased
--     edges pick up correct partial alpha instead of white fringing.
--   * Safe to key white here (unlike Capstone, where white was kept because its
--     mark is white-on-red): this badge is line art in black + teal with no
--     white-filled shapes, so nothing is lost.
--   * RGB snapped to a 3-colour palette (black / #0797B0 teal / white) to get
--     the file from 341KB down to 168KB, in line with the other logos. The mark
--     is flat colour with no gradients, so this is lossless in appearance.
--
-- Note the badge is SQUARE (1:1), unlike every other sponsor logo, which are
-- all wide. It will therefore render small: the Blue bounding box is
-- max-h-24/max-w-[200px] on /sponsors, so it lands ~96x96, and the homepage
-- strip caps non-MVP logos at max-h-12, so ~48x48 there. That is the tier
-- system working as designed, not a bug -- but if Freddie's ever asks why their
-- logo looks smaller than a Gold sponsor's, that is the reason.
--
-- Idempotent.

begin;

insert into sponsors (name, logo_url, website_url, tier_id, sort_order, year, active)
select 'Freddie''s Carwash',
       'freddies-carwash.png',
       'https://freddiescarwash.com',
       t.id,
       7,
       '2026-27',
       true
from sponsorship_tiers t
where t.year = '2026-27'
  and t.name = 'Blue'
  and t.active
  and not exists (
    select 1 from sponsors s
    where s.year = '2026-27' and s.name = 'Freddie''s Carwash'
  );

commit;

-- ===
-- db/migrations/113_program_ad_closed_for_season.sql
-- ===

-- 113_program_ad_closed_for_season.sql
--
-- The game-day program has gone to print. Sponsors can no longer buy space in
-- it, so the "Program Ad" add-on must stop being offered on /boosters/sponsor.
-- Jeremy confirmed 2026-08-04: "we can't get sponsors in the program any
-- longer. that deadline did pass."
--
-- The card was still live and still reading "Commit by July 31 to make this
-- season's program", i.e. advertising a closed window with a date four days in
-- the past. A business could have clicked "Add This Add-On" and committed money
-- for something we cannot deliver.
--
-- DEACTIVATED, NOT DELETED. Same reasoning as migration 111 (Rudy's): every
-- public sponsor/tier query filters `.eq('active', true)`, so active=false is
-- equivalent to gone on the site while the row, its price_display, and its
-- description survive for next season. Program ads come back every year; a
-- fresh INSERT next season is how you end up with duplicate concepts (see the
-- 041/094 Rudy's history). Reactivate this row instead.
--
-- SCOPE: this touches ONE add-on row. It does NOT touch the Blue -> MVP base
-- ladder, and it does NOT touch the Tunnel or Scoreboard add-ons, which are
-- both still sellable. The Add-Ons section on /boosters/sponsor keeps rendering
-- with those two.
--
-- NOT IN SCOPE, already self-cleaned (verified 2026-08-04, no action needed):
--   - The "Senior Shoutouts" hero carousel tile had expires_at 2026-08-01 and is
--     already hidden by the expiry filter in lib/queries/hero.ts.
--   - The "Reserve a Senior Shoutout" event starts_at is 2026-08-01 04:59Z
--     (= Jul 31 11:59 PM CDT), so /events already lists it under Past.
--   Those are the separate $25 parent-facing senior ad, not this sponsor add-on.
--
-- STILL TO DO OUTSIDE THIS MIGRATION: the live sponsorship Google Form's
-- "Add-ons (optional)" question still offers three Program Ad choices
-- ($100 / $150 / $250). A migration cannot reach a Google Form. Run
-- `removeProgramAdChoices` in MavericksWebsite/scripts/update-sponsor-form-assets.gs
-- as mcneilfootballboosters@gmail.com. Until that runs, the form can still take
-- a program-ad order that the site no longer advertises.

begin;

-- Guard: fail loudly if the row isn't where we think it is, rather than
-- reporting success after updating zero rows.
do $$
declare
  n int;
begin
  select count(*) into n
  from sponsorship_tiers
  where year = '2026-27' and is_addon and name = 'Program Ad' and active;

  if n <> 1 then
    raise exception
      'Expected exactly 1 active 2026-27 Program Ad add-on row, found %. Aborting.', n;
  end if;
end $$;

update sponsorship_tiers
set active = false
where year = '2026-27'
  and is_addon
  and name = 'Program Ad';

commit;

-- Verification (expect: Tunnel t, Scoreboard t, Program Ad f):
--   select name, active from sponsorship_tiers
--   where year='2026-27' and is_addon order by sort_order;
--
-- /boosters/sponsor is force-dynamic, so this goes live with no deploy.

-- ===
-- db/migrations/114_event_photos.sql
-- ===

-- 114_event_photos.sql
--
-- Photo albums for past events. Jeremy 2026-08-08, prompted by the Aug 7 pool
-- party.
--
-- DESIGN: the album URL lives on the EVENT, and `/resources` gets exactly ONE
-- durable row pointing at the past-events list. The tempting alternative — a
-- resource_links row per album, mirroring the existing "Game Photos" row — was
-- rejected: Game Photos works because it is one permanent destination, whereas
-- event albums accrue one per event forever. That turns Forms & Links into a
-- junk drawer and adds a manual step someone eventually forgets. One row that
-- never needs touching, plus per-event links set once at album-creation time.
--
-- ⚠️ PRIVACY, raised with Jeremy before shipping: a photos.app.goo.gl link is
-- public to anyone holding it, and these are photos of minors. Publishing it on
-- the site makes the album genuinely public. Jeremy owns club photos and made
-- the call. `photos_url` is NULLABLE and the UI renders nothing when it is null,
-- so pulling an album back down is a one-line UPDATE with no deploy.
--
-- ⚠️ Album links rot silently. If someone deletes or unshares an album, the site
-- shows a dead link with no signal. Nothing here can detect that.

begin;

alter table events
  add column if not exists photos_url text;

comment on column events.photos_url is
  'Public photo-album URL for this event (e.g. a Google Photos shared album). '
  'NULL = no album; every render site must hide its affordance when null. '
  'Public to anyone with the link — do not set for events where that is not intended.';

-- The Aug 7 pool party album.
update events
set photos_url = 'https://photos.app.goo.gl/ojcaEm5ndmngmAak9'
where slug = 'pool-party-2026';

-- One durable Forms & Links entry. Points at the past-events list rather than a
-- single album, so this row is correct forever and no future album needs a new
-- row. Sits under News & Communications next to Game Photos (sort_order 4).
-- icon_hint 'photo' -> lucide Camera, registered by migration 051.
insert into resource_links (label, url, description, section, sort_order, icon_hint, active)
select
  'Event Photos',
  '/events?filter=past',
  'Photo albums from past Booster Club events. Open a past event to view its album.',
  'communications',
  5,
  'photo',
  true
where not exists (
  select 1 from resource_links where label = 'Event Photos'
);

commit;

-- Verification:
--   select slug, photos_url from events where photos_url is not null;
--   select label, url, section, sort_order from resource_links where label = 'Event Photos';
--
-- Both /events and /resources read at request time, so this goes live with no
-- deploy once the rendering code ships.

-- ===
-- db/migrations/115_community_partners.sql
-- ===

-- 115_community_partners.sql
--
-- Community Partners: businesses that give in-kind support (meals, gift cards,
-- product) rather than buying a sponsorship level. They get acknowledged with a
-- logo and a link on /boosters/donate, and are NOT sold as a tier.
--
-- Jeremy 2026-08-08, replacing the earlier "Friends level" idea. The point of
-- moving them to the donate page is that they never imply a purchased level.
--
-- ⚠️ ACKNOWLEDGMENT, NOT ADVERTISING. The club is a 501(c)(3). Under the
-- qualified-sponsorship rules, showing a partner's name, logo and a plain link
-- is acknowledgment; adding promotional language (taglines, discounts, offers,
-- qualitative claims, calls to action) turns it into advertising income. The
-- render deliberately carries NO description/tagline field for that reason —
-- do not add one. Also do NOT publish a dollar value for an in-kind gift;
-- valuing it is the donor's job for their own return, not ours.
--
-- ── DESIGN: one explicit column, not an inferred marker ──
-- `kind` discriminates instead of leaning on `tier_id IS NULL`. There are
-- currently ZERO untiered sponsors, so a null tier means "someone forgot to
-- pick one" and it should keep meaning exactly that. Inferring partner-ness
-- from a missing value would make a data-entry slip silently publish a paying
-- sponsor in the wrong place.
--
-- ⚠️ EVERY sponsor-facing surface must filter `kind = 'sponsor'`. There are
-- three (app/page.tsx, app/sponsors/page.tsx, app/boosters/sponsor/page.tsx).
-- Miss one and a partner renders as a paying sponsor — which is precisely the
-- Rudy's failure this project already shipped twice (041 seeded it as a
-- placeholder, 060 removed it, 094 re-added it on a bad confirmation, 106
-- carried it forward, 111 finally deactivated it).
--
-- ── RUDY'S: the row is CONVERTED, never re-inserted ──
-- Rudy's has now genuinely agreed to provide meals (Jeremy 2026-08-08), so they
-- are a real Community Partner. Migration 111's note says explicitly: "Don't
-- write a fresh INSERT — that's how this ended up duplicated in concept across
-- 041/094." So this reuses the existing 2026-27 row, preserving its id and
-- created_at, and flips it from a deactivated MVP sponsor to an active partner.
--
-- The 2025-26 row is deliberately LEFT INACTIVE. Rudy's was never a sponsor in
-- that season and is not retroactively a partner either.

begin;

alter table sponsors
  add column if not exists kind text not null default 'sponsor';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'sponsors_kind_check'
  ) then
    alter table sponsors
      add constraint sponsors_kind_check
      check (kind in ('sponsor', 'community_partner'));
  end if;
end $$;

comment on column sponsors.kind is
  'sponsor = bought a sponsorship level, renders on /sponsors + the homepage strip. '
  'community_partner = in-kind support (meals, gift cards), renders ONLY on '
  '/boosters/donate. Every sponsor-facing query must filter kind = ''sponsor''.';

-- Guard: fail loudly rather than silently updating zero rows.
do $$
declare
  n int;
begin
  select count(*) into n
  from sponsors
  where year = '2026-27' and name = 'Rudy''s BBQ';

  if n <> 1 then
    raise exception
      'Expected exactly 1 Rudy''s BBQ row for 2026-27, found %. Aborting.', n;
  end if;
end $$;

update sponsors
set kind       = 'community_partner',
    tier_id    = null,   -- was MVP; a partner has no purchased level
    active     = true,   -- 111 deactivated it; they are now real
    sort_order = 1
where year = '2026-27'
  and name = 'Rudy''s BBQ';

commit;

-- Verification:
--   select name, year, kind, active, tier_id, sort_order
--   from sponsors where name ilike '%rud%' order by year;
--     -> 2025-26 : sponsor / inactive  (untouched)
--     -> 2026-27 : community_partner / active / tier_id NULL
--
--   select kind, count(*) from sponsors where year='2026-27' and active group by kind;
--     -> sponsor 6, community_partner 1
--
-- /boosters/donate is ISR revalidate=300, so allow ~5 min. /sponsors and
-- /boosters/sponsor are force-dynamic and update immediately.

-- ===
-- db/migrations/116_community_partners_batch.sql
-- ===

-- 116_community_partners_batch.sql
--
-- Seven more Community Partners, supplied by Jeremy 2026-08-08. All in-kind
-- (meals, food, gift cards) — none of them bought a sponsorship level.
--
-- ⚠️ Name + logo + link only, per migration 115. No taglines, no descriptions,
-- no dollar values. The club is a 501(c)(3): acknowledgment is fine, promotional
-- copy would be advertising. There is deliberately no column here to put one in.
--
-- ── ORDERING: sort_order 0 for every partner, on purpose ──
-- getCommunityPartners orders by sort_order THEN name, so leaving all partners
-- at 0 makes the list alphabetical automatically and means adding a partner
-- never requires picking a number or renumbering anything. It also avoids
-- implying a ranking among in-kind supporters, which is the whole point of not
-- having levels here. Rudy's is dropped from 1 to 0 to join the same scheme.
--
-- ── URL NOTES (each verified HTTP 200 on 2026-08-08 before writing) ──
-- ⚠️ Tony C's: the URL originally supplied was `tonycspizza.com`, which is WRONG
--    twice over — it serves a near-empty page titled "TC4 Beer Garden" with no
--    mention of Tony C's, and it has NO TLS (https returns nothing at all), so
--    linking it from an https site would have been a broken, insecure link.
--    Corrected to tonycs.com, confirmed as the real site and confirmed to list
--    the Avery Ranch location on W Parmer Ln that the logo names.
-- Chicoine had no URL supplied; chicoinechiropractic.com was located and then
--    confirmed by Jeremy. Title reads "North Austin Chiropractor in Wells
--    Branch", consistent with the McNeil feeder area.
-- Phil's and Tony C's both point at location-specific pages, as supplied.
--
-- Logos: prepped by MavericksWebsite/partner_logos/prep_logos.py from PINNED
-- sources in that folder. No white-keying was applied to any of them — four are
-- white text on a coloured field (Jack Allen's, The League, Phil's, Mighty Fine)
-- where keying would eat the lettering, and the rest sit on white, which is
-- invisible against this page anyway. Same call as Capstone's white-on-red mark.

begin;

-- Alphabetical-by-name ordering for all partners, including the existing row.
update sponsors set sort_order = 0
where kind = 'community_partner' and year = '2026-27';

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select v.name, v.logo_url, v.website_url, null, '2026-27', 'community_partner', true, 0, false
from (values
  ('Amy''s Ice Creams',           'amys-ice-creams.png',       'https://amysicecreams.com/'),
  ('Chicoine Chiropractic',       'chicoine-chiropractic.png', 'https://chicoinechiropractic.com/'),
  ('Jack Allen''s Kitchen',       'jack-allens.png',           'https://jackallenskitchen.com/'),
  ('Mighty Fine Burgers',         'mighty-fine.png',           'https://www.mightyfineburgers.com/'),
  ('Phil''s Icehouse',            'phils-icehouse.png',        'https://www.philsicehouse.com/phils-in-north-austinville/'),
  ('The League Kitchen & Tavern', 'the-league.png',            'https://www.leaguekitchen.com/'),
  ('Tony C''s Coal Fired Pizza',  'tony-cs.png',               'https://www.tonycs.com/locations#order-now-section')
) as v(name, logo_url, website_url)
where not exists (
  select 1 from sponsors s
  where s.name = v.name and s.year = '2026-27' and s.kind = 'community_partner'
);

commit;

-- Verification:
--   select name, logo_url, website_url from sponsors
--   where kind='community_partner' and year='2026-27' and active
--   order by sort_order, name;
--     -> 8 rows, alphabetical, Rudy's sixth
--
--   select kind, count(*) from sponsors where year='2026-27' and active group by kind;
--     -> sponsor 6, community_partner 8
--
-- /boosters/donate is ISR revalidate=300, so allow ~5 minutes.

-- ===
-- db/migrations/117_scoreboard_tier_and_w_homes.sql
-- ===

-- 117_scoreboard_tier_and_w_homes.sql
--
-- Three things, all from Jeremy 2026-08-08:
--   1. W Homes Collective joins as a GOLD sponsor.
--   2. Rudy's BBQ is a PAYING SPONSOR after all — $3,000 for two years as the
--      Scoreboard sponsor — so it moves back out of Community Partners.
--   3. The Scoreboard tier gets an explicit showcase rank so it displays just
--      above Platinum rather than above Diamond.
--
-- ── RUDY'S, ONE MORE TIME ──
-- This is the FIFTH state change for this one row, so the history matters:
--   041 seeded as an MVP placeholder · 060 removed as fake · 094 re-added on a
--   bad confirmation · 106 carried into 2026-27 · 111 deactivated ("not a
--   sponsor and never was") · 115 reactivated as a Community Partner (meals) ·
--   117 (this) converts to a PAYING Scoreboard sponsor.
-- Jeremy confirmed they paid $3,000 for a two-season scoreboard sponsorship, and
-- his own headcount ("on the homepage you'll be up to 8" = 6 existing + W Homes
-- + Rudy's) independently confirms Rudy's belongs on the sponsor side now.
--
-- ⚠️ Rudy's is removed from Community Partners rather than listed in both.
-- Paying sponsor supersedes in-kind acknowledgment; showing one business in both
-- places reads as double-counting. They may well still be donating meals — if
-- both should show, that's a deliberate call to make, not a default.
-- Partners drop 8 -> 7.
--
-- STILL a conversion, never an INSERT — same reason as 115. The row keeps its id
-- and created_at through all of this.
--
-- ── WHY showcase_rank_cents EXISTS ──
-- /sponsors orders tiers by price_cents DESC. Scoreboard's price_cents is
-- 300000 ($3,000 total), which would sort it ABOVE Diamond ($2,500/season) —
-- but it is a TWO-SEASON commitment, so its annualised value is $1,500, level
-- with Platinum. Jeremy's call: display it just above Platinum.
--
-- Rather than fake the price (it really is $3,000, and /boosters/sponsor sells
-- it at that number), this adds an explicit, nullable showcase rank. NULL means
-- "rank by price", so every existing tier is unaffected and nothing had to be
-- backfilled. Only a tier whose term differs from one season needs a value.
-- 175000 sits between Platinum (150000) and Diamond (250000).

begin;

alter table sponsorship_tiers
  add column if not exists showcase_rank_cents integer;

comment on column sponsorship_tiers.showcase_rank_cents is
  'Optional override for /sponsors showcase ordering, in cents. NULL = rank by '
  'price_cents. Exists for multi-season tiers whose headline price does not '
  'reflect their per-season value (Scoreboard is $3,000 across two seasons, so '
  'it ranks near Platinum''s $1,500/season rather than above Diamond).';

update sponsorship_tiers
set showcase_rank_cents = 175000
where year = '2026-27' and name = 'Scoreboard';

-- Guards: fail loudly rather than silently updating nothing.
do $$
declare
  n_rudys int;
  n_score int;
  n_gold  int;
begin
  select count(*) into n_rudys from sponsors
    where year = '2026-27' and name = 'Rudy''s BBQ';
  select count(*) into n_score from sponsorship_tiers
    where year = '2026-27' and name = 'Scoreboard' and active;
  select count(*) into n_gold from sponsorship_tiers
    where year = '2026-27' and name = 'Gold' and active;

  if n_rudys <> 1 then
    raise exception 'Expected 1 Rudy''s row for 2026-27, found %', n_rudys;
  end if;
  if n_score <> 1 then
    raise exception 'Expected 1 active Scoreboard tier, found %', n_score;
  end if;
  if n_gold <> 1 then
    raise exception 'Expected 1 active Gold tier, found %', n_gold;
  end if;
end $$;

-- Rudy's: community partner -> paying Scoreboard sponsor, first in display order.
update sponsors
set kind       = 'sponsor',
    tier_id    = (select id from sponsorship_tiers
                  where year = '2026-27' and name = 'Scoreboard' and active),
    sort_order = 1,
    active     = true
where year = '2026-27'
  and name = 'Rudy''s BBQ';

-- Renumber so the homepage carousel order is explicit and gap-free, with the
-- largest commitment first. The carousel pins whichever sponsor sorts first.
update sponsors set sort_order = 2 where year='2026-27' and kind='sponsor' and name='Capstone Acquisitions';
update sponsors set sort_order = 3 where year='2026-27' and kind='sponsor' and name='North Austin Oral Surgery';
update sponsors set sort_order = 4 where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order = 6 where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order = 7 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order = 8 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';

-- W Homes Collective, Gold. sort_order 5 puts it immediately after Laurie Flood,
-- the other Gold sponsor.
insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select 'W Homes Collective', 'w-homes-collective.png', 'https://whomescollective.com/',
       (select id from sponsorship_tiers where year='2026-27' and name='Gold' and active),
       '2026-27', 'sponsor', true, 5, false
where not exists (
  select 1 from sponsors where name = 'W Homes Collective' and year = '2026-27'
);

commit;

-- Verification:
--   select s.sort_order, s.name, t.name tier from sponsors s
--   left join sponsorship_tiers t on t.id = s.tier_id
--   where s.kind='sponsor' and s.year='2026-27' and s.active order by s.sort_order;
--     -> 8 rows, Rudy's/Scoreboard first, W Homes/Gold fifth
--   select kind, count(*) from sponsors where year='2026-27' and active group by kind;
--     -> sponsor 8, community_partner 7

-- ===
-- db/migrations/118_practice_week2_earlier.sql
-- ===

-- 118_practice_week2_earlier.sql
--
-- Coach moved next week's practice EARLIER for both groups because of a
-- teacher/coach professional development change. Relayed by Jeremy 2026-08-08,
-- ahead of the Weekly MAV Reminder going out 2026-08-09.
--
--   Upperclassmen : arrive 6:00, on field 6:25, done 9:50  (was 6:30-10:00)
--   Freshmen      : arrive 8:35, on field 8:55, done 10:30 (was 9:00-11:00)
--
-- Week 1 (Aug 3-9) is REMOVED — it has run, and Jeremy asked for it to come off.
-- Next week is promoted out of the "tentative" bullet list into real day blocks
-- with arrival / on-field / end times, matching how Week 1 was presented.
--
-- ⚠️ SCOPE OF THE NEW TIMES. Coach supplied ONE set of times for "next week",
-- so they are applied to the four weekday practices (Mon 10, Tue 11, Wed 12,
-- Fri 14). Thursday Aug 13 is the Hendrickson scrimmage, not a practice, and is
-- untouched. SATURDAY AUG 15 IS ALSO UNTOUCHED (upperclassmen 9:00-11:00,
-- freshmen no practice) because Coach did not mention it — the section says so
-- in-copy rather than silently implying Saturday moved too. If Coach's reminder
-- tomorrow says otherwise, Friday and Saturday are the two to re-check.
--
-- The freshman "Wed Aug 12 — 9:00-11:00 (or 6:30-8:30 PM)" alternative is gone:
-- the new time is a specific commitment, not a choice of two.
--
-- Bodies were BUILT BY TRANSFORMING THE LIVE ROWS, not retyped: the Aug 17-28
-- tentative list is carried across verbatim. Asserted before writing that all
-- ten remaining tentative dates survive, both scrimmage references survive, no
-- Week 1 content remains, and each new time appears on exactly four days.
-- 118_rollback.sql restores the previous bodies byte-exact.

begin;

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 2 — August 10–16

**Monday through Friday times below are Coach's updated times** — practice moves earlier next week because of a teacher/coach professional development change. Saturday is unchanged from the preseason plan.

### Monday, Aug 10
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Tuesday, Aug 11
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Wednesday, Aug 12
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Thursday, Aug 13
See Games: scrimmage vs Hendrickson (home)

### Friday, Aug 14
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Saturday, Aug 15
- **9:00–11:00 a.m.** — Practice

## After Week 2 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 6:30–10:00
- **Tue Aug 18** — 6:30–10:00
- **Wed Aug 19** — 6:20–8:15 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 7:00–8:00 · Picture day
- **Mon Aug 24** — 6:00–8:15
- **Tue Aug 25** — 6:00–8:15
- **Wed Aug 26** — 6:20–8:15
- **Thu Aug 27** — 7:50–8:30
- **Fri Aug 28** — See Games: game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'varsity';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 2 — August 10–16

**Monday through Friday times below are Coach's updated times** — practice moves earlier next week because of a teacher/coach professional development change. Saturday is unchanged from the preseason plan.

### Monday, Aug 10
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Tuesday, Aug 11
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Wednesday, Aug 12
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Thursday, Aug 13
See Games: scrimmage vs Hendrickson (home)

### Friday, Aug 14
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — On the field
- **9:50 a.m.** — Practice ends

### Saturday, Aug 15
- **9:00–11:00 a.m.** — Practice

## After Week 2 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 6:30–10:00
- **Tue Aug 18** — 6:30–10:00
- **Wed Aug 19** — 6:20–8:15 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 7:00–8:00 · Picture day
- **Mon Aug 24** — 6:00–8:15
- **Tue Aug 25** — 6:00–8:15
- **Wed Aug 26** — 6:20–8:15
- **Thu Aug 27** — 7:50–8:30
- **Fri Aug 28** — See Games: game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'jv';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time.

## Week 2 — August 10–16

**Monday through Friday times below are Coach's updated times** — practice moves earlier next week because of a teacher/coach professional development change. Saturday is unchanged from the preseason plan.

### Monday, Aug 10
- **8:35 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Tuesday, Aug 11
- **8:35 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Wednesday, Aug 12
- **8:35 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Thursday, Aug 13
See Games: scrimmage vs Hendrickson (home)

### Friday, Aug 14
- **8:35 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Saturday, Aug 15
No practice.

## After Week 2 — tentative

**Everything below is tentative and subject to change.** See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 9:00–11:00
- **Tue Aug 18** — 9:00–11:00
- **Wed Aug 19** — 8:10–9:45 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 8:00–10:15 · Picture day
- **Mon Aug 24** — 8:10–9:50
- **Tue Aug 25** — 8:10–9:50
- **Wed Aug 26** — 8:10–9:50
- **Thu Aug 27** — 8:45–9:50
- **Fri Aug 28** — 8:30–9:50 · Game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'freshman';

commit;

-- Verification:
--   select team_level, body like '%Week 2%' as has_wk2, body like '%Week 1%' as has_wk1
--   from practice_schedules where year='2026-27';
--   -> has_wk2 t, has_wk1 f for all three
--
-- /schedule/practice/* reads at request time, so this is live with no deploy.

-- ===
-- db/migrations/119_rudys_also_in_kind.sql
-- ===

-- 119_rudys_also_in_kind.sql
--
-- Rudy's BBQ is BOTH: a paying Scoreboard sponsor ($3,000 / two seasons) AND an
-- in-kind supporter providing meals. Jeremy confirmed 2026-08-08, answering the
-- question migration 117 deliberately left open.
--
-- ── WHY A SECOND COLUMN AND NOT A SECOND ROW ──
-- `kind` is single-valued, so expressing "both" needs something. The options
-- were a duplicate sponsors row, widening `kind`, or a separate flag.
--
-- A duplicate row was rejected outright. This is the single most churned row in
-- the database (041 seed → 060 remove → 094 re-add → 106 carry → 111 deactivate
-- → 115 partner → 117 sponsor), and every prior mess came from the concept
-- existing in more than one place at once. Two live Rudy's rows would mean two
-- things to keep in sync and two things to forget.
--
-- So: `kind` keeps meaning "what did this business BUY" — the thing that decides
-- whether they belong on the sponsor surfaces — and the new flag records the
-- separate fact that they also give in kind. One row, two orthogonal facts.
--
-- Effect: Rudy's renders on /sponsors + the homepage carousel as a Scoreboard
-- sponsor (unchanged), AND in Community Partners on /boosters/donate.
-- Partners go 7 -> 8.
--
-- ⚠️ The three sponsor surfaces still filter `kind = 'sponsor'` and must NOT be
-- taught about this flag. A community_partner must never leak onto them; this
-- flag only ever ADDS a business to the donate page.

begin;

alter table sponsors
  add column if not exists provides_in_kind boolean not null default false;

comment on column sponsors.provides_in_kind is
  'TRUE when this business also gives in-kind support (meals, gift cards) on top '
  'of whatever `kind` says they bought. Community Partners on /boosters/donate = '
  'kind = ''community_partner'' OR provides_in_kind. Independent of `kind`: a '
  'paying sponsor can be both, which is why this is not another `kind` value.';

do $$
declare n int;
begin
  select count(*) into n from sponsors
  where year = '2026-27' and name = 'Rudy''s BBQ' and kind = 'sponsor';
  if n <> 1 then
    raise exception 'Expected 1 Rudy''s sponsor row for 2026-27, found %', n;
  end if;
end $$;

update sponsors
set provides_in_kind = true
where year = '2026-27' and name = 'Rudy''s BBQ';

commit;

-- Verification:
--   select name, kind, provides_in_kind from sponsors
--   where year='2026-27' and active and (kind='community_partner' or provides_in_kind)
--   order by name;
--     -> 8 rows: the 7 partners plus Rudy's (kind=sponsor, provides_in_kind=t)
--
--   select count(*) from sponsors where year='2026-27' and active and kind='sponsor';
--     -> still 8; the sponsor surfaces are unaffected

-- ===
-- db/migrations/120_practice_week2_from_coach_doc.sql
-- ===

-- 120_practice_week2_from_coach_doc.sql
--
-- Week 2 rewritten from Coach's actual "MAV FOOTBALL WEEKLY SCHEDULE,
-- August 10-15, 2026" doc, which Jeremy sent 2026-08-09. This CORRECTS
-- migration 118, which was built from a verbal relay the day before.
--
-- ── WHAT 118 GOT WRONG (all six, verified against the doc) ──
--   Upper Mon-Wed end   9:50      -> 10:00
--   Fresh Mon-Wed arrive 8:35     -> 8:30
--   Thursday            "See Games" placeholder -> full morning + scrimmage times
--   Friday              regular practice        -> WEIGHTS / CONDITIONING / FILM
--   Saturday upper      9:00-11:00              -> 7:00 / 7:25 / 10:30
--   Saturday freshmen   "No practice"           -> 9:30 / 9:55 / 10:45
--
-- Friday and Saturday were the two days 118 explicitly flagged as unconfirmed
-- because Coach had only given one set of times for "next week". Both were
-- wrong, and Friday was not even a practice. Established rule, reconfirmed:
-- treat Coach's weekly doc as authoritative over any verbal relay or seeded
-- preseason grid.
--
-- ⚠️ JV NOW DIFFERS FROM VARSITY ON THURSDAY — first time these two bodies have
-- diverged. Coach's doc has two columns, UPPERCLASSMEN (SOPH/JR/SR) and
-- FRESHMEN, so JV has always shared the upperclassmen body. But Thursday's
-- freshmen cell is labelled "FRESHMAN & JV SCRIMMAGE" at 5:30 p.m., while the
-- upperclassmen cell has a 7:00 p.m. scrimmage. Read literally, a JV athlete
-- does the 7:35 a.m. upperclassmen practice and then scrimmages at 5:30 with the
-- freshmen, NOT at 7:00.
-- This is an INFERENCE from a doc that is internally ambiguous (JV are sophomores
-- and so also sit inside the upperclassmen column). It is called out to Jeremy.
-- Publishing 7:00 for JV would have been the more dangerous guess: a JV family
-- reading it would arrive 90 minutes after their scrimmage started.
--
-- Meet the Mavs added to BOTH Friday blocks, marked mandatory, per Jeremy — it
-- doubles as a reminder. Time and venue taken from the events row seeded by
-- migration 108 (Fri Aug 14, 6:00-8:00 p.m., McNeil High School Stadium) rather
-- than retyped, so the practice page and /events cannot drift.
--
-- Bodies built by transforming the live rows; the Aug 17-28 tentative tail is
-- carried across verbatim. Assertions were scoped to the WEEK 2 SECTION — a
-- whole-body check for the stale "9:50" false-positives on the legitimate
-- "Aug 24 - 8:10-9:50" tentative entry.

begin;

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 2 — August 10–15

Times below are Coach's published MAV Football Weekly Schedule for August 10–15.

### Monday, Aug 10
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Tuesday, Aug 11
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Wednesday, Aug 12
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Thursday, Aug 13
**Morning practice**
- **7:35 a.m.** — Arrival
- **8:00 a.m.** — On the field

**Scrimmage vs Hendrickson**
- **5:50 p.m.** — Arrival
- **6:30 p.m.** — Stretch lines begin on the field
- **7:00 p.m.** — Scrimmage begins at McNeil High School Stadium

### Friday, Aug 14
- **8:15 a.m.** — Arrival
- **8:30 a.m.** — Weights / Conditioning / Film begins
- **6:00–8:00 p.m.** — Meet the Mavs at McNeil High School Stadium (**mandatory**)

### Saturday, Aug 15
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — Stretch lines begin on the field
- **10:30 a.m.** — Practice ends

## After Week 2 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 6:30–10:00
- **Tue Aug 18** — 6:30–10:00
- **Wed Aug 19** — 6:20–8:15 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 7:00–8:00 · Picture day
- **Mon Aug 24** — 6:00–8:15
- **Tue Aug 25** — 6:00–8:15
- **Wed Aug 26** — 6:20–8:15
- **Thu Aug 27** — 7:50–8:30
- **Fri Aug 28** — See Games: game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'varsity';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 2 — August 10–15

Times below are Coach's published MAV Football Weekly Schedule for August 10–15.

### Monday, Aug 10
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Tuesday, Aug 11
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Wednesday, Aug 12
- **6:00 a.m.** — Arrival
- **6:25 a.m.** — Stretch lines begin on the field
- **10:00 a.m.** — Practice ends

### Thursday, Aug 13
**Morning practice**
- **7:35 a.m.** — Arrival
- **8:00 a.m.** — On the field

**Freshman & JV scrimmage**
- **4:30 p.m.** — Arrival
- **4:55 p.m.** — On the field
- **5:30 p.m.** — Scrimmage begins at McNeil High School Stadium

### Friday, Aug 14
- **8:15 a.m.** — Arrival
- **8:30 a.m.** — Weights / Conditioning / Film begins
- **6:00–8:00 p.m.** — Meet the Mavs at McNeil High School Stadium (**mandatory**)

### Saturday, Aug 15
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — Stretch lines begin on the field
- **10:30 a.m.** — Practice ends

## After Week 2 — tentative

**Everything below is tentative and subject to change.** Times are AM unless noted. See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 6:30–10:00
- **Tue Aug 18** — 6:30–10:00
- **Wed Aug 19** — 6:20–8:15 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 7:00–8:00 · Picture day
- **Mon Aug 24** — 6:00–8:15
- **Tue Aug 25** — 6:00–8:15
- **Wed Aug 26** — 6:20–8:15
- **Thu Aug 27** — 7:50–8:30
- **Fri Aug 28** — See Games: game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'jv';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time.

## Week 2 — August 10–15

Times below are Coach's published MAV Football Weekly Schedule for August 10–15.

### Monday, Aug 10
- **8:30 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Tuesday, Aug 11
- **8:30 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Wednesday, Aug 12
- **8:30 a.m.** — Arrival
- **8:55 a.m.** — On the field
- **10:30 a.m.** — Practice ends

### Thursday, Aug 13
**No morning practice.**

**Freshman & JV scrimmage**
- **4:30 p.m.** — Arrival
- **4:55 p.m.** — On the field
- **5:30 p.m.** — Scrimmage begins at McNeil High School Stadium

### Friday, Aug 14
- **7:15 a.m.** — Early arrival
- **7:30 a.m.** — Weights / Film / Conditioning begins
- **6:00–8:00 p.m.** — Meet the Mavs at McNeil High School Stadium (**mandatory**)

### Saturday, Aug 15
- **9:30 a.m.** — Arrival
- **9:55 a.m.** — On the field
- **10:45 a.m.** — Practice ends

## After Week 2 — tentative

**Everything below is tentative and subject to change.** See the Games schedule for scrimmages and Game 1.

- **Mon Aug 17** — 9:00–11:00
- **Tue Aug 18** — 9:00–11:00
- **Wed Aug 19** — 8:10–9:45 · First day of school
- **Thu Aug 20** — See Games: scrimmage vs Eastview (home), time TBD
- **Fri Aug 21** — 8:00–10:15 · Picture day
- **Mon Aug 24** — 8:10–9:50
- **Tue Aug 25** — 8:10–9:50
- **Wed Aug 26** — 8:10–9:50
- **Thu Aug 27** — 8:45–9:50
- **Fri Aug 28** — 8:30–9:50 · Game 1 at Bowie (away)
$body$
where year = '2026-27' and team_level = 'freshman';

commit;

-- /schedule/practice/* reads at request time: live with no deploy.

-- ===
-- db/migrations/121_santiagos_partner.sql
-- ===

-- 121_santiagos_partner.sql
--
-- Santiago's Tex-Mex & Cantina (Cat Hollow) joins Community Partners. In-kind,
-- so no tier. Jeremy 2026-08-09. URL verified 200: title "Tex-Mex Cantina &
-- Margaritas in Round Rock TX | Santiago's".
--
-- Logo was pulled from THEIR OWN SITE, not the screenshot supplied:
-- static.spotapps.co/.../custom/logo.png carries real transparency, whereas the
-- screenshot had a solid black backing that would have rendered as a black tile.
-- (It is also what Kendra's own asset spec asks sponsors for: not a screenshot.)
-- ⚠️ Only 142x171, so it is soft on retina — a larger original would be better.
--
-- sort_order 0 like every other partner: the partner list orders by NAME, so
-- nothing needs renumbering when one is added.

begin;

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select 'Santiago''s Tex-Mex & Cantina', 'santiagos.png',
       'https://cathollow.santiagostexmexandcantina.com/',
       null, '2026-27', 'community_partner', true, 0, false
where not exists (
  select 1 from sponsors where name = 'Santiago''s Tex-Mex & Cantina' and year = '2026-27'
);

commit;

-- ===
-- db/migrations/122_meal_sponsors_tier.sql
-- ===

-- 122_meal_sponsors_tier.sql
--
-- New "Meal" level, displayed between Platinum and Gold, holding the businesses
-- that feed the teams. Jeremy 2026-08-09.
--
-- Members: Mighty Fine Burgers, The League Kitchen & Tavern, Tony C's Coal Fired
-- Pizza. All three move OUT of Community Partners and onto the sponsor side.
--
-- ⚠️ RUDY'S STAYS ON SCOREBOARD. Jeremy listed Rudy's among the meal sponsors
-- but said explicitly "leave rudy's as scoreboard", so its tier is untouched —
-- Scoreboard outranks Meal and is what they actually paid for. What DOES change
-- is that Rudy's leaves Community Partners with the other three, so
-- provides_in_kind goes back to false. Rudy's therefore appears exactly once,
-- under Scoreboard. (That flag was added by 119 for the opposite reason two days
-- ago; it stays on the table because it is still the right mechanism, just no
-- longer true of anyone right now.)
--
-- ── Tier NAME is "Meal", not "Meal Sponsors" ──
-- /sponsors renders its heading as `{tier.name} Sponsors`, so "Meal Sponsors"
-- would print "MEAL SPONSORS SPONSORS". Same convention as Scoreboard/Blue/Gold.
--
-- ── Why price_cents = 0 and a showcase rank ──
-- A meal sponsor gives food, not money, so there is no honest dollar price.
-- price_cents 0 would sort it dead last on /sponsors, hence
-- showcase_rank_cents = 125000, between Gold (100000) and Platinum (150000) —
-- exactly the slot asked for. Same mechanism migration 117 added for Scoreboard.
--
-- ── New `sellable` column: why this tier must NOT reach /boosters/sponsor ──
-- That page builds the purchasable ladder from every active tier. Without a
-- guard, Meal would render as a buyable level showing "In-kind" and NO benefits,
-- inviting people to sign up for something with no defined price or perks.
-- `active` cannot express this: /sponsors filters on active too, so switching it
-- off would hide the tier from the showcase as well — the one place it must
-- appear. Hence a separate flag.
-- ⚠️ OPEN QUESTION for Jeremy: if meal sponsorship should actually be sellable,
-- flip sellable to true and give the tier a price/term and perks copy. Left
-- unsellable because inventing benefits text for a level nobody has defined
-- would be fabrication.

begin;

alter table sponsorship_tiers
  add column if not exists sellable boolean not null default true;

comment on column sponsorship_tiers.sellable is
  'FALSE = display-only: the tier groups sponsors on /sponsors but is NOT offered '
  'on the /boosters/sponsor sign-up ladder. For recognition groupings with no '
  'price or published benefits (Meal). Distinct from `active`, which hides a tier '
  'from BOTH surfaces.';

do $$
declare n int;
begin
  select count(*) into n from sponsorship_tiers
    where year='2026-27' and name in ('Gold','Platinum') and active;
  if n <> 2 then
    raise exception 'Expected active Gold and Platinum tiers, found %', n;
  end if;
  select count(*) into n from sponsors
    where year='2026-27' and active
      and name in ('Mighty Fine Burgers','The League Kitchen & Tavern','Tony C''s Coal Fired Pizza');
  if n <> 3 then
    raise exception 'Expected the 3 meal businesses, found %', n;
  end if;
end $$;

insert into sponsorship_tiers
  (name, price_cents, description, perks, sort_order, active, year,
   is_addon, price_flexible, price_display, showcase_rank_cents, sellable)
select 'Meal', 0,
       'Local restaurants feeding the McNeil Football teams.',
       '[]'::jsonb, 3, true, '2026-27', false, true, 'In-kind', 125000, false
where not exists (
  select 1 from sponsorship_tiers where year='2026-27' and name='Meal'
);

update sponsors
set kind             = 'sponsor',
    provides_in_kind = false,
    tier_id          = (select id from sponsorship_tiers
                        where year='2026-27' and name='Meal'),
    sort_order       = v.ord
from (values
  ('Mighty Fine Burgers', 4),
  ('The League Kitchen & Tavern', 5),
  ('Tony C''s Coal Fired Pizza', 6)
) as v(nm, ord)
where sponsors.year='2026-27' and sponsors.name = v.nm;

-- Rudy's: out of Community Partners, tier untouched.
update sponsors set provides_in_kind = false
where year='2026-27' and name='Rudy''s BBQ';

-- Renumber the rest so carousel order still tracks tier order.
update sponsors set sort_order=7  where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order=8  where year='2026-27' and kind='sponsor' and name='W Homes Collective';
update sponsors set sort_order=9  where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=10 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order=11 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';

commit;

-- Verification:
--   select s.sort_order, s.name, t.name tier from sponsors s
--   left join sponsorship_tiers t on t.id=s.tier_id
--   where s.kind='sponsor' and s.year='2026-27' and s.active order by s.sort_order;
--     -> 11 rows; Scoreboard, Platinum x2, Meal x3, Gold x2, Blue x3
--   select name from sponsors where year='2026-27' and active
--     and (kind='community_partner' or provides_in_kind) order by name;
--     -> 5: Amy's, Chicoine, Jack Allen's, Phil's, Santiago's

-- ===
-- db/migrations/123_rudys_to_meal.sql
-- ===

-- 123_rudys_to_meal.sql
--
-- Rudy's moves from Scoreboard to Meal, and the Scoreboard section comes off
-- /sponsors for now. Jeremy 2026-08-09.
--
-- ⚠️ THE SCOREBOARD TIER IS NOT DEACTIVATED, DELIBERATELY.
-- /sponsors already renders nothing for a tier with no sponsors, so moving
-- Rudy's out is by itself enough to hide the section — no flag needed. Setting
-- the tier inactive would ALSO pull Scoreboard off the /boosters/sponsor sign-up
-- ladder, where it is still a real, sellable $3,000 / two-season add-on that
-- nobody asked to withdraw. Hiding a showcase section and withdrawing a product
-- are different things; this does only the first.
--
-- Rudy's did pay $3,000 for scoreboard placement, so the site no longer shows
-- what they bought. Jeremy said "for now", so treat this as temporary: to undo,
-- move the tier_id back (123_rollback.sql) and the section returns on its own.
--
-- Sponsors renumbered so display order still tracks tier order, with Meal
-- members alphabetical among themselves.

begin;

do $$
declare n int;
begin
  select count(*) into n from sponsorship_tiers where year='2026-27' and name='Meal' and active;
  if n <> 1 then raise exception 'Expected 1 active Meal tier, found %', n; end if;
end $$;

update sponsors
set tier_id = (select id from sponsorship_tiers where year='2026-27' and name='Meal')
where year='2026-27' and name='Rudy''s BBQ';

update sponsors set sort_order=1  where year='2026-27' and kind='sponsor' and name='Capstone Acquisitions';
update sponsors set sort_order=2  where year='2026-27' and kind='sponsor' and name='North Austin Oral Surgery';
update sponsors set sort_order=3  where year='2026-27' and kind='sponsor' and name='Mighty Fine Burgers';
update sponsors set sort_order=4  where year='2026-27' and kind='sponsor' and name='Rudy''s BBQ';
update sponsors set sort_order=5  where year='2026-27' and kind='sponsor' and name='The League Kitchen & Tavern';
update sponsors set sort_order=6  where year='2026-27' and kind='sponsor' and name='Tony C''s Coal Fired Pizza';
update sponsors set sort_order=7  where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order=8  where year='2026-27' and kind='sponsor' and name='W Homes Collective';
update sponsors set sort_order=9  where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=10 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order=11 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';

commit;

-- Verification:
--   select s.sort_order, s.name, t.name tier from sponsors s
--   join sponsorship_tiers t on t.id=s.tier_id
--   where s.kind='sponsor' and s.year='2026-27' and s.active order by s.sort_order;
--     -> Platinum x2, Meal x4 (incl. Rudy's), Gold x2, Blue x3; no Scoreboard

-- ===
-- db/migrations/124_meal_to_gold.sql
-- ===

-- 124_meal_to_gold.sql
--
-- The Meal level is retired one day after being created (migration 122). Its
-- four members move down to Gold. Jeremy 2026-08-09.
--
-- Mighty Fine Burgers, Rudy's BBQ, The League Kitchen & Tavern and Tony C's
-- Coal Fired Pizza all become Gold sponsors, joining Laurie Flood and W Homes.
-- Gold goes 2 -> 6.
--
-- ⚠️ The Meal tier is DEACTIVATED, not deleted — the project's standing pattern
-- (111 Rudy's, 113 Program Ad). active=false removes it from both /sponsors and
-- the /boosters/sponsor ladder, so it is invisible everywhere while the row,
-- its showcase rank and its sellable=false flag survive for a one-line revert.
-- Deleting would also throw away the only row exercising `sellable`.
--
-- Note this leaves Rudy's, who paid $3,000 for a two-season scoreboard, sitting
-- in the $1,000 Gold tier — below what they actually bought. Migration 123
-- already moved them off Scoreboard "for now" at Jeremy's request; this is a
-- further step in the same direction and is his call, but it is worth being
-- explicit that the site now under-represents that sponsorship.
--
-- Within Gold the six are ordered ALPHABETICALLY, matching how partners are
-- ordered: no ranking is implied among sponsors at the same level.

begin;

do $$
declare n int;
begin
  select count(*) into n from sponsorship_tiers where year='2026-27' and name='Gold' and active;
  if n <> 1 then raise exception 'Expected 1 active Gold tier, found %', n; end if;
  select count(*) into n from sponsors s join sponsorship_tiers t on t.id=s.tier_id
   where s.year='2026-27' and t.name='Meal' and s.active;
  if n <> 4 then raise exception 'Expected 4 Meal sponsors to move, found %', n; end if;
end $$;

update sponsors
set tier_id = (select id from sponsorship_tiers where year='2026-27' and name='Gold' and active)
where year='2026-27'
  and tier_id = (select id from sponsorship_tiers where year='2026-27' and name='Meal');

update sponsorship_tiers set active = false
where year='2026-27' and name='Meal';

update sponsors set sort_order=1  where year='2026-27' and kind='sponsor' and name='Capstone Acquisitions';
update sponsors set sort_order=2  where year='2026-27' and kind='sponsor' and name='North Austin Oral Surgery';
update sponsors set sort_order=3  where year='2026-27' and kind='sponsor' and name='Laurie Flood Real Estate Team';
update sponsors set sort_order=4  where year='2026-27' and kind='sponsor' and name='Mighty Fine Burgers';
update sponsors set sort_order=5  where year='2026-27' and kind='sponsor' and name='Rudy''s BBQ';
update sponsors set sort_order=6  where year='2026-27' and kind='sponsor' and name='The League Kitchen & Tavern';
update sponsors set sort_order=7  where year='2026-27' and kind='sponsor' and name='Tony C''s Coal Fired Pizza';
update sponsors set sort_order=8  where year='2026-27' and kind='sponsor' and name='W Homes Collective';
update sponsors set sort_order=9  where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=10 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';
update sponsors set sort_order=11 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';

commit;

-- Verification: Platinum x2, Gold x6, Blue x3; no Meal section anywhere.

-- ===
-- db/migrations/125_meet_the_mavs_7pm.sql
-- ===

-- 125_meet_the_mavs_7pm.sql
--
-- Meet the Mavs starts at 7:00 PM, not 6:00 PM. Jeremy 2026-08-13, the day
-- before the event.
--
-- ── Where the wrong time came from ──
-- 6:00 PM was the BOOSTER CLUB's call time (volunteers on site to set up), not
-- the time families arrive. Migration 108 had inherited 6:00-8:00 PM wholesale
-- from the 2025 event and flagged it at the time as "INHERITED ... not
-- independently confirmed for 2026". That flag was correct and this is it
-- coming due.
--
-- ⚠️ TWO PLACES, NOT ONE. The time is stored in the events row AND written into
-- the Friday block of all three practice bodies (migration 120). Migration 120's
-- note said the time was read from the events row "so the practice page and
-- /events cannot drift" — that was true at BUILD time only; the text is baked
-- into markdown, so it drifts the moment the event row changes. Both must move
-- together. If a future edit changes this event again, grep the practice bodies.
--
-- ⚠️ END TIME IS UNCHANGED AT 8:00 PM AND IS *NOT* CONFIRMED. Jeremy corrected
-- only the start. 8:00 PM is the same inherited-from-2025 value that produced
-- the wrong start, so it is suspect for the same reason — the event may well run
-- to 9:00. Only the corrected fact is applied here; the end is left alone rather
-- than shifted by an hour on a guess. Flagged to Jeremy.
--
-- The 6:00 PM booster call time is deliberately NOT published. It is an internal
-- volunteer instruction, and putting it on a family-facing page would send
-- families an hour early — which is the confusion this migration is fixing.

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug='meet-the-mavs-2026'
     and to_char(starts_at at time zone 'America/Chicago','HH24:MI') = '18:00';
  if n <> 1 then
    raise exception 'Expected Meet the Mavs starting 18:00 CT, found % matching row(s)', n;
  end if;
  select count(*) into n from practice_schedules
   where year='2026-27' and body like '%**6:00–8:00 p.m.** — Meet the Mavs%';
  if n <> 3 then
    raise exception 'Expected 3 practice bodies with the 6:00 Meet the Mavs line, found %', n;
  end if;
end $$;

update events
set starts_at = timestamptz '2026-08-14 19:00 America/Chicago'
where slug = 'meet-the-mavs-2026';

update practice_schedules
set body = replace(
      body,
      '- **6:00–8:00 p.m.** — Meet the Mavs',
      '- **7:00–8:00 p.m.** — Meet the Mavs')
where year = '2026-27'
  and body like '%**6:00–8:00 p.m.** — Meet the Mavs%';

commit;

-- Verification:
--   select to_char(starts_at at time zone 'America/Chicago','YYYY-MM-DD HH12:MI AM'),
--          to_char(ends_at   at time zone 'America/Chicago','HH12:MI AM')
--   from events where slug='meet-the-mavs-2026';        -> 2026-08-14 07:00 PM | 08:00 PM
--   select count(*) from practice_schedules
--    where year='2026-27' and body like '%6:00–8:00 p.m.%';   -> 0
--
-- /events and /schedule/practice/* read at request time; the homepage is ISR
-- revalidate=60. No deploy required.

-- ===
-- db/migrations/126_meet_the_mavs_back_to_6pm.sql
-- ===

-- 126_meet_the_mavs_back_to_6pm.sql
--
-- Meet the Mavs is 6:00-8:00 PM after all. Jeremy 2026-08-13, hours after
-- migration 125 moved it to 7:00 PM on the opposite information.
--
-- Net effect: back to what migration 108 originally seeded. 125 + 126 cancel out.
--
-- ── Why this is a FORWARD migration and not just running 125_rollback.sql ──
-- Running the rollback would fix the live database but leave `db/apply_all.sql`
-- — the forward-only bundle — still ending at 125, so anyone rebuilding a
-- database from it would land on 7:00 PM and silently disagree with production.
-- Rollback scripts are for undoing an unshipped mistake in place; once a
-- migration has shipped, reversing it is its own forward step.
--
-- ⚠️ THE TIME HAS NOW FLIPPED TWICE IN ONE DAY on contradicting information from
-- the school. 6:00 PM is ALSO the value migration 108 inherited from the 2025
-- event without independent confirmation, so arriving back here does not mean it
-- has been verified — it means two sources disagreed and the second one won.
-- If it changes again, get it from whoever owns the event and note the source.
--
-- Both places again: the events row AND the Friday block in all three practice
-- bodies. They do not share a source at runtime; the practice text is markdown.

begin;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug='meet-the-mavs-2026'
     and to_char(starts_at at time zone 'America/Chicago','HH24:MI') = '19:00';
  if n <> 1 then
    raise exception 'Expected Meet the Mavs starting 19:00 CT, found % matching row(s)', n;
  end if;
  select count(*) into n from practice_schedules
   where year='2026-27' and body like '%**7:00–8:00 p.m.** — Meet the Mavs%';
  if n <> 3 then
    raise exception 'Expected 3 practice bodies with the 7:00 line, found %', n;
  end if;
end $$;

update events
set starts_at = timestamptz '2026-08-14 18:00 America/Chicago'
where slug = 'meet-the-mavs-2026';

update practice_schedules
set body = replace(
      body,
      '- **7:00–8:00 p.m.** — Meet the Mavs',
      '- **6:00–8:00 p.m.** — Meet the Mavs')
where year = '2026-27'
  and body like '%**7:00–8:00 p.m.** — Meet the Mavs%';

commit;

-- ===
-- db/migrations/127_atfcu_blue_sponsor.sql
-- ===

-- 127_atfcu_blue_sponsor.sql
--
-- Austin Telco Federal Credit Union joins at BLUE ($500). Jeremy 2026-08-14.
--
-- URL verified before writing: atfcu.org and www.atfcu.org both 200 and the
-- title reads "Austin Telco Federal Credit Union", so this is the right ATFCU
-- (there are several similarly-abbreviated Texas credit unions — A+ FCU and
-- RBFCU both appear in sponsor_online_asks_2026.md and are NOT this one).
--
-- Display name is the full "Austin Telco Federal Credit Union" rather than the
-- lowercase "atfcu" wordmark in the logo: the name is what screen readers
-- announce and what the aria-label says, and the initialism alone tells a
-- visitor nothing.
--
-- Logo: vendor-supplied primary mark, 1276x301 with real transparency and no
-- background panel — trimmed on its alpha bbox, no judgement needed about what
-- was padding vs artwork. Renders 200x45 in the Blue 200x96 box.
--
-- ── Blue is renumbered ALPHABETICALLY while we are here ──
-- It was 9/10/11 in historical add-order (Luv Braces, Mama Betty's, Freddie's).
-- Gold and Community Partners are both already alphabetical within their group,
-- so this brings Blue in line and means the next Blue sponsor slots in by name
-- instead of landing at the end. No ranking is implied within a tier.

begin;

do $$
declare n int;
begin
  select count(*) into n from sponsorship_tiers where year='2026-27' and name='Blue' and active;
  if n <> 1 then raise exception 'Expected 1 active Blue tier, found %', n; end if;
end $$;

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select 'Austin Telco Federal Credit Union', 'atfcu.png', 'https://www.atfcu.org/',
       (select id from sponsorship_tiers where year='2026-27' and name='Blue' and active),
       '2026-27', 'sponsor', true, 9, false
where not exists (
  select 1 from sponsors where name='Austin Telco Federal Credit Union' and year='2026-27'
);

-- Blue, alphabetical: ATFCU(9) · Freddie's(10) · Luv Braces(11) · Mama Betty's(12)
update sponsors set sort_order=10 where year='2026-27' and kind='sponsor' and name='Freddie''s Carwash';
update sponsors set sort_order=11 where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=12 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';

commit;

-- Verification: 12 active sponsors — Platinum x2, Gold x6, Blue x4.

-- ===
-- db/migrations/128_kathy_sokolic_and_round_rock_express.sql
-- ===

-- 128_kathy_sokolic_and_round_rock_express.sql
--
-- Two additions, Jeremy 2026-08-14:
--   Kathy Sokolic, REALTOR®  -> BLUE sponsor ($500)
--   Round Rock Express       -> Community Partner
--
-- Both URLs verified 200 before writing: kathysokolicrealtor.com (title
-- "Realtor in Austin, TX"; www redirects to the apex, so the apex is stored) and
-- mlb.com/milb/round-rock (title "Official Round Rock Express Website").
--
-- ── ⚠️ KATHY'S LOGO: the first file supplied was the WHITE version ──
-- Kathy_Logo_White_LG.svg is 24 white fills to 5 blue. Both surfaces it would
-- appear on have WHITE backgrounds, so most of the mark would have been
-- invisible — the wordmark would have vanished and left a floating stripe.
-- Caught by counting fills before rendering; Jeremy supplied the black version.
-- Rasterised from Kathy_Logo_Black_LG.svg (24x #000000, 5x #2a74b8).
-- The bucket only accepts png/jpeg/webp, so SVGs are rasterised through headless
-- Chrome — same route Mama Betty's took.
--
-- ── ⚠️ ROUND ROCK: the supplied JPEG had a FAKE transparent background ──
-- "Dell Diamond Round Rock Express Logo.jpg" has the Photoshop transparency
-- CHECKERBOARD baked in as real pixels (corners alternate 255,255,255 and
-- 220,220,220). Published as-is it would render a grey checked rectangle. JPEG
-- cannot carry alpha at all, so there was nothing to recover.
-- Used the official mark from mlbstatic.com/team-logos/102.svg instead — real
-- vector, genuine transparency, and current. Same call as Santiago's, where the
-- screenshot had a black backing and their own site had the real file.
-- ⚠️ This is the "E" shield, MLB's canonical team logo, NOT the older
-- ROUND ROCK EXPRESS wordmark-with-train in Jeremy's image. If the wordmark is
-- wanted, it needs a clean source — the JPEG cannot provide one.
--
-- Also rejected: images.ctfassets.net/.../round-rock-affiliate-logo.svg, which
-- is the TEXAS RANGERS parent-club affiliate mark and is mostly white.
--
-- Blue stays alphabetical (127's scheme), so Kathy slots in at 11 and the two
-- below her shift. Partners carry sort_order 0 and are ordered by NAME at query
-- time, so Round Rock Express needs no renumbering.

begin;

do $$
declare n int;
begin
  select count(*) into n from sponsorship_tiers where year='2026-27' and name='Blue' and active;
  if n <> 1 then raise exception 'Expected 1 active Blue tier, found %', n; end if;
end $$;

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select 'Kathy Sokolic, REALTOR®', 'kathy-sokolic.png', 'https://kathysokolicrealtor.com/',
       (select id from sponsorship_tiers where year='2026-27' and name='Blue' and active),
       '2026-27', 'sponsor', true, 11, false
where not exists (
  select 1 from sponsors where name='Kathy Sokolic, REALTOR®' and year='2026-27'
);

-- Blue alphabetical: ATFCU(9) · Freddie's(10) · Kathy(11) · Luv Braces(12) · Mama Betty's(13)
update sponsors set sort_order=12 where year='2026-27' and kind='sponsor' and name='Luv Braces';
update sponsors set sort_order=13 where year='2026-27' and kind='sponsor' and name='Mama Betty''s Tex-Mex';

insert into sponsors (name, logo_url, website_url, tier_id, year, kind, active, sort_order, featured)
select 'Round Rock Express', 'round-rock-express.png', 'https://www.mlb.com/milb/round-rock',
       null, '2026-27', 'community_partner', true, 0, false
where not exists (
  select 1 from sponsors where name='Round Rock Express' and year='2026-27'
);

commit;

-- Verification: 13 active sponsors (Platinum 2 · Gold 6 · Blue 5), 6 partners.

-- ===
-- db/migrations/129_practice_week3_from_coach_doc.sql
-- ===

-- 129_practice_week3_from_coach_doc.sql
--
-- Week 3 written from Coach's published "MAV FOOTBALL WEEKLY SCHEDULE,
-- August 17-23, 2026 - ONE MAV NATION" doc, which Jeremy sent 2026-08-16.
-- Replaces the Week 2 bodies (migration 120) and the tentative Aug 17-28 tail
-- that 077 seeded.
--
-- ── THE TENTATIVE TAIL WAS DROPPED, NOT CARRIED ──
-- 120 carried the "After Week 2 - tentative" list across verbatim. That list is
-- now demonstrably wrong for the school year: it had Mon Aug 17 at 6:30-10:00
-- (real: 7:00-10:15) and Wed Aug 19 at 6:20-8:15 (real: on the field 10:45 a.m.,
-- during Period 2). Once school starts, practice moves INSIDE the school day, so
-- the Aug 24-28 estimates in that tail - all early-morning windows inherited
-- from the 077 preseason grid - would publish a practice time no one will keep.
-- A parent reading "Mon Aug 24 - 6:00-8:15" would show up four hours early.
-- Replaced with a pointer to next week's doc plus the Games schedule, which is
-- real data. Restore the tail only if Coach publishes actual Week 4 times.
--
-- ⚠️ JV/THURSDAY AMBIGUITY - same call as migration 120, same reasoning.
-- The doc's two columns are UPPERCLASSMEN (SOPH/JR/SR) and FRESHMEN, so JV
-- shares the upperclassmen body. But Thursday's upperclassmen cell reads
-- "SCRIMMAGE - UPPERCLASSMEN 1ST & 2ND GROUP" at 7:00 p.m. while the freshmen
-- cell reads "FRESHMAN & JV SCRIMMAGE" at 5:30 p.m. Read literally, a JV athlete
-- practices Period 6 with the upperclassmen and then scrimmages at 5:30 with the
-- freshmen. JV therefore gets the 5:30 block, NOT 7:00 - publishing 7:00 would
-- put a JV family 90 minutes late. This matches how the Aug 13 Hendrickson
-- scrimmage is already seeded in `games` (JV 5:30, varsity 7:00, migration 078),
-- so the two surfaces agree.
--
-- Wednesday and Thursday upperclassmen cells give NO arrival time - only
-- "PERIOD 2" / "PERIOD 6", on the field 10:45, ends 12:00. Transcribed as
-- written; no arrival time was invented.
--
-- Saturday and Sunday are PLAYERS: OFF. The coaches' scouting/workday blocks in
-- those cells are staff-facing and are summarised in one line rather than
-- reprinted - the practice page is read by families.
--
-- Meet the Mavs (Fri Aug 14) leaves the bodies with Week 2. That closes the
-- drift risk the Status section flagged: the event time now lives only in the
-- `events` row.
--
-- Companion: migration 130 puts the Thursday scrimmage times from this same doc
-- onto the four Aug 20 Eastview `games` rows, which were seeded time-TBD.

begin;

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 3 — August 17–23

Times below are Coach's published MAV Football Weekly Schedule for August 17–23.

### Monday, Aug 17
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — On the field
- **10:15 a.m.** — Practice ends

### Tuesday, Aug 18
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — On the field
- **10:15 a.m.** — Practice ends

### Wednesday, Aug 19 — first day of school
**Practice is during Period 2.**
- **10:45 a.m.** — On the field
- **12:00 p.m.** — Practice ends

### Thursday, Aug 20
**Practice is during Period 6.**
- **10:45 a.m.** — On the field
- **12:00 p.m.** — Practice ends

**Scrimmage vs Eastview — upperclassmen 1st & 2nd group**
- **6:00 p.m.** — Arrival
- **6:25 p.m.** — On the field
- **7:00 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium

### Friday, Aug 21 — picture day
- **7:00 a.m.** — Arrival
- **8:00 a.m.** — Pictures complete
- Film during Period 2

### Saturday, Aug 22
**Players: off.** Coaches complete scouting input and the next-opponent breakdown.

### Sunday, Aug 23
**Players: off.** Coaches workday.

## After Week 3

Week 4 times will be posted when Coach publishes next week's schedule. See the Games schedule for Game 1 vs Bowie — JV and freshmen Thursday Aug 27, varsity Friday Aug 28.
$body$
where year = '2026-27' and team_level = 'varsity';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time. Varsity and JV practice together.

## Week 3 — August 17–23

Times below are Coach's published MAV Football Weekly Schedule for August 17–23.

### Monday, Aug 17
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — On the field
- **10:15 a.m.** — Practice ends

### Tuesday, Aug 18
- **7:00 a.m.** — Arrival
- **7:25 a.m.** — On the field
- **10:15 a.m.** — Practice ends

### Wednesday, Aug 19 — first day of school
**Practice is during Period 2.**
- **10:45 a.m.** — On the field
- **12:00 p.m.** — Practice ends

### Thursday, Aug 20
**Practice is during Period 6.**
- **10:45 a.m.** — On the field
- **12:00 p.m.** — Practice ends

**Freshman & JV scrimmage vs Eastview**
- **4:30 p.m.** — Arrival
- **4:55 p.m.** — On the field
- **5:30 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium

### Friday, Aug 21 — picture day
- **7:00 a.m.** — Arrival
- **8:00 a.m.** — Pictures complete
- Film during Period 2

### Saturday, Aug 22
**Players: off.** Coaches complete scouting input and the next-opponent breakdown.

### Sunday, Aug 23
**Players: off.** Coaches workday.

## After Week 3

Week 4 times will be posted when Coach publishes next week's schedule. See the Games schedule for Game 1 vs Bowie — JV and freshmen Thursday Aug 27, varsity Friday Aug 28.
$body$
where year = '2026-27' and team_level = 'jv';

update practice_schedules set body = $body$Athletes must be dressed, prepared, and ready to begin at the listed on-field start time.

## Week 3 — August 17–23

Times below are Coach's published MAV Football Weekly Schedule for August 17–23.

### Monday, Aug 17
- **9:00 a.m.** — Arrival
- **9:20 a.m.** — On the field
- **10:40 a.m.** — Practice ends

### Tuesday, Aug 18
- **9:00 a.m.** — Arrival
- **9:20 a.m.** — On the field
- **10:40 a.m.** — Practice ends

### Wednesday, Aug 19 — first day of school
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:40 a.m.** — Practice ends

### Thursday, Aug 20
**Morning practice**
- **8:00 a.m.** — Arrival
- **8:25 a.m.** — On the field
- **9:40 a.m.** — Practice ends

**Freshman & JV scrimmage vs Eastview**
- **4:30 p.m.** — Arrival
- **4:55 p.m.** — On the field
- **5:30 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium

### Friday, Aug 21 — picture day
- **8:00 a.m.** — Arrival
- **9:15 a.m.** — Pictures complete
- Film after pictures, time permitting

### Saturday, Aug 22
**Players: off.** Coaches complete scouting input and the next-opponent breakdown.

### Sunday, Aug 23
**Players: off.** Coaches workday.

## After Week 3

Week 4 times will be posted when Coach publishes next week's schedule. See the Games schedule for Game 1 vs Bowie — JV and freshmen Thursday Aug 27, varsity Friday Aug 28.
$body$
where year = '2026-27' and team_level = 'freshman';

-- ── assertions ──────────────────────────────────────────────────────────────
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and body like '%Week 3 — August 17–23%';
  if n <> 3 then raise exception 'expected 3 week-3 bodies, got %', n; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and (body like '%Week 2%' or body like '%Aug 10%'
                               or body like '%Aug 13%' or body like '%Aug 15%'
                               or body like '%Meet the Mavs%' or body like '%tentative%');
  if n <> 0 then raise exception 'stale week-2/tentative text left in % bodies', n; end if;

  -- Thursday scrimmage: varsity 7:00 p.m. only; JV and freshmen 5:30 p.m. only.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'varsity'
     and body like '%7:00 p.m.%' and body not like '%5:30 p.m.%';
  if n <> 1 then raise exception 'varsity thursday scrimmage time wrong'; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('jv', 'freshman')
     and body like '%5:30 p.m.%' and body not like '%7:00 p.m.%';
  if n <> 2 then raise exception 'jv/freshman thursday scrimmage time wrong'; end if;

  -- Upperclassmen Wed/Thu are in-school-day; freshmen are not.
  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level in ('varsity', 'jv')
     and body like '%Period 2%' and body like '%Period 6%' and body like '%12:00 p.m.%';
  if n <> 2 then raise exception 'upperclassmen in-school-day blocks missing'; end if;

  select count(*) into n from practice_schedules
   where year = '2026-27' and team_level = 'freshman'
     and body like '%9:40 a.m.%' and body not like '%Period%';
  if n <> 1 then raise exception 'freshman wed/thu block wrong'; end if;
end $$;

commit;

-- /schedule/practice/* reads at request time: live with no deploy.

-- ===
-- db/migrations/130_eastview_scrimmage_times.sql
-- ===

-- 130_eastview_scrimmage_times.sql
--
-- The Thu Aug 20 Eastview scrimmage finally has times, from the same source as
-- migration 129: Coach's "MAV FOOTBALL WEEKLY SCHEDULE, August 17-23, 2026" doc.
--
-- Migration 078 seeded these four rows with `result_status = 'tbd'` because the
-- coaches' calendar had no time. The stored 6:00 PM was an explicit placeholder
-- and the games views render "TBD" in the time cell for tbd rows - so nothing
-- wrong was ever published, but the page has said TBD for a scrimmage that is
-- now four days out.
--
--   Upperclassmen (1st & 2nd group)  7:00 p.m.  -> varsity
--   Freshman & JV                    5:30 p.m.  -> jv, freshman Green + Blue
--
-- Identical split to the Aug 13 Hendrickson scrimmage 078 seeded as firm, and to
-- the JV reading taken in migrations 120 and 129. If that JV reading is ever
-- corrected, THIS ROW MOVES TOO - the practice bodies and the games rows have to
-- be changed together or a JV family gets two different scrimmage times off the
-- same site.
--
-- Location is left NULL, matching Hendrickson. The doc says "McNeil High School
-- Mavericks Stadium", which is what `home_or_away = 'home'` already conveys on
-- the games surfaces; the two other home rows carry no location string and
-- adding one only here would look like a different venue.

begin;

update games
   set game_date = '2026-08-20 19:00:00-05'::timestamptz,
       result_status = 'scheduled'
 where year = '2026-27' and opponent = 'Eastview High School'
   and team_level = 'varsity';

update games
   set game_date = '2026-08-20 17:30:00-05'::timestamptz,
       result_status = 'scheduled'
 where year = '2026-27' and opponent = 'Eastview High School'
   and (team_level = 'jv' or team_level = 'freshman');

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and opponent = 'Eastview High School';
  if n <> 4 then raise exception 'expected 4 Eastview rows, got %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Eastview High School'
     and result_status = 'tbd';
  if n <> 0 then raise exception '% Eastview rows still tbd', n; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Eastview High School'
     and game_date = '2026-08-20 19:00:00-05'::timestamptz;
  if n <> 1 then raise exception 'expected exactly 1 Eastview row at 7:00 PM, got %', n; end if;

  select count(*) into n from games
   where year = '2026-27' and opponent = 'Eastview High School'
     and game_date = '2026-08-20 17:30:00-05'::timestamptz;
  if n <> 3 then raise exception 'expected 3 Eastview rows at 5:30 PM, got %', n; end if;
end $$;

commit;

-- /schedule/games/* reads at request time: live with no deploy.

-- ===
-- db/migrations/131_meet_the_mavs_photos.sql
-- ===

-- 131_meet_the_mavs_photos.sql
--
-- Photo album for the Aug 14 Meet the Mavs, supplied by Jeremy 2026-08-16. Second
-- use of the `events.photos_url` mechanism from migration 114 (the Aug 7 pool
-- party was the first), so this is a one-column UPDATE and nothing else - no new
-- resource_links row. 114's "Event Photos" entry already points at the past-events
-- list and covers every album from here on.
--
-- Link verified before writing: https://photos.app.goo.gl/fFYzH6d5hxPfyKok6
-- resolves 200 to photos.google.com/share/... and the album's own title is
-- "Meet the Mavs 2026 - 2027", og:title "Meet the Mavs 2026 - 2027 · Friday,
-- Aug 14" - the right event, not a same-name album from another season.
--
-- ⚠️ Carries forward 114's privacy note, unchanged: a photos.app.goo.gl link is
-- public to anyone holding it, and these are photos of minors. Publishing it here
-- makes the album genuinely public. Jeremy owns club photos and made the call for
-- the pool party and again for this one. Pulling it back down is
--   update events set photos_url = null where slug = 'meet-the-mavs-2026';
-- with no deploy - `/events` and the detail page both hide the affordance on null.
--
-- ⚠️ Album links rot silently. If the album is deleted or unshared, the site shows
-- a dead "View Photos" button with no signal. Nothing here can detect that.

begin;

update events
   set photos_url = 'https://photos.app.goo.gl/fFYzH6d5hxPfyKok6'
 where slug = 'meet-the-mavs-2026';

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'meet-the-mavs-2026'
     and photos_url = 'https://photos.app.goo.gl/fFYzH6d5hxPfyKok6';
  if n <> 1 then raise exception 'meet-the-mavs-2026 photos_url not set (matched % rows)', n; end if;
end $$;

commit;

-- /events and /events/[slug] read at request time: live with no deploy.
-- Verification:
--   select slug, photos_url from events where photos_url is not null;

-- ===
-- db/migrations/132_eastview_scrimmage_location.sql
-- ===

-- 132_eastview_scrimmage_location.sql
--
-- Puts the venue on the four Aug 20 Eastview rows: 'Maverick Stadium'.
--
-- ⚠️ This REVERSES a decision made in migration 130 hours earlier. 130 left
-- location NULL on purpose, reasoning that `home_or_away = 'home'` already says
-- where it is and that the Aug 13 Hendrickson rows carry no location either.
-- Two things changed since:
--   1. The Print View PDF now names the venue on those rows (Maverick Stadium),
--      so the site saying nothing where its own PDF says something is a gap.
--   2. The games rows are about to be rendered onto /events, the month view and
--      the ICS feed. A calendar entry with no location is materially worse than
--      a schedule table with an empty SITE cell - a phone calendar shows the
--      location under the title and offers directions from it.
-- Documented rather than quietly re-done: 130's note is wrong now, and anyone
-- reading it needs to land here.
--
-- 'Maverick Stadium' is the exact string the other home rows in this table use
-- (JV and freshman home games), so the games tables stay internally consistent
-- and the calendar entries read the same as every other home fixture. Varsity
-- home DISTRICT games are at 'KRAC' and are untouched - the scrimmage is the
-- exception, which is the whole point.
--
-- The past Aug 13 Hendrickson rows are deliberately left NULL. They are done,
-- nobody is navigating to them, and editing played rows earns nothing.

begin;

update games
   set location = 'Maverick Stadium'
 where year = '2026-27'
   and opponent = 'Eastview High School'
   and location is null;

do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and opponent = 'Eastview High School'
     and location = 'Maverick Stadium';
  if n <> 4 then raise exception 'expected 4 Eastview rows at Maverick Stadium, got %', n; end if;

  -- Nothing else in the season should have lost or gained a venue.
  select count(*) into n from games
   where year = '2026-27' and game_date >= '2026-08-20' and location is null;
  if n <> 0 then raise exception '% upcoming games still have no venue', n; end if;
end $$;

commit;

-- /schedule/games/* reads at request time: live with no deploy.

-- ===
-- db/migrations/133_event_picture_day_2026.sql
-- ===

-- 133_event_picture_day_2026.sql
--
-- Football Picture Day, Friday August 21. Jeremy 2026-08-16, off Coach's weekly
-- schedule for Aug 17-23 (the same doc migration 129 published). It stays on the
-- practice pages as well - explicitly fine per Jeremy - because a family reading
-- Friday's practice block should not have to know to also check /events.
--
-- ONE EVENT, NOT TWO. The doc gives two different windows:
--     Upperclassmen  7:00 arrival -> 8:00 pictures complete, film during Period 2
--     Freshmen       8:00 arrival -> 9:15 pictures complete, film after if time
-- Seeded as a single 7:00-9:15 a.m. row with both windows spelled out in the
-- description, rather than two rows. Two rows would put two overlapping
-- "Picture Day" entries on every subscribed calendar and force every parent to
-- work out which one is theirs; one row with both times is unambiguous whichever
-- group you are in. This is the same call migration 102 made for the equipment
-- pickups, where both groups' times went in the description of a single row.
--
-- ⚠️ The 9:15 END is the freshmen "pictures complete" time, and the 7:00 START is
-- the upperclassmen arrival - i.e. the envelope of both groups, not one group's
-- window. Do not read the event's own times as any single athlete's call time;
-- that is what the description is for.
--
-- Location is the school, not the stadium: the doc gives no room and picture day
-- has historically been indoors. `location_url` is the same campus pin the Meet
-- the Mavs row uses (migration 108) rather than a new guess at a building.
--
-- August 2026 is CDT, hence -05.

begin;

insert into events (title, slug, description, starts_at, ends_at, location, location_url, status)
values (
  'Football Picture Day',
  'picture-day-2026',
  'Team and individual photos for all three levels. Upperclassmen (Soph/Jr/Sr): 7:00 a.m. arrival, pictures complete by 8:00 a.m., film during Period 2. Freshmen: 8:00 a.m. arrival, pictures complete by 9:15 a.m., film after pictures if time permits.',
  '2026-08-21 07:00:00-05',
  '2026-08-21 09:15:00-05',
  'McNeil High School',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published'
)
on conflict (slug) do nothing;

do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'picture-day-2026' and status = 'published'
     and starts_at = '2026-08-21 07:00:00-05'::timestamptz
     and ends_at   = '2026-08-21 09:15:00-05'::timestamptz;
  if n <> 1 then raise exception 'picture-day-2026 not seeded as expected (matched % rows)', n; end if;
end $$;

commit;

-- /events reads at request time: live with no deploy.

-- ===
-- db/migrations/134_venues.sql
-- ===

-- 134_venues.sql
--
-- A `venues` table, and `venue_id` on games + events. Jeremy 2026-08-16, after
-- noticing that "Burger Stadium" on the schedule is not a link.
--
-- ── WHY A TABLE AND NOT JUST FILLING IN location_url ──
-- Both tables have had a `location_url` column since the beginning; it is NULL on
-- all 48 game rows and always has been, which is the entire reason the schedule
-- has no map links (the games table and game cards already render one the moment
-- the value exists). Filling in 48 URLs would have worked today and rotted
-- tomorrow: 18 rows say 'Maverick Stadium' and 5 say 'KRAC', so a corrected pin
-- would be 18 edits, and every new game row would need someone to remember to
-- paste a URL. One row per place, referenced by id, is the fix.
--
-- It also unlocks the thing a URL alone cannot do: the ICS feed can now emit
-- "Burger Stadium, 3200 Jones Road, Austin, TX" as the LOCATION, so a subscribed
-- phone can navigate to a Thursday away game. That needs a street address, which
-- there was nowhere to put.
--
-- ── ONE SOURCE, NOT TWO ──
-- `events.location_url` is CLEARED wherever a venue is attached, and the column
-- is left in place but deprecated (see the comment set below). A row that can
-- carry a link in two columns is the same drift trap as Meet the Mavs' time
-- living in an events row and in the practice markdown. One place.
--
-- ── ADDRESS SOURCING - every pin is from the school district or from Jeremy ──
--   McNeil                     already used site-wide (migration 108)
--   Kelly Reeves (KRAC)        Round Rock ISD facility page
--   Dragon Stadium             Jeremy 2026-08-16, with a Google Maps place link
--   Toney Burger Stadium       Austin ISD athletics page (3200, NOT the 3600 that
--                              several listing sites carry); link from Jeremy
--   Gupton Stadium             Leander ISD stadiums page
--   Chaparral Stadium          Westlake athletics facilities page
--   Opponent campuses          each district's own campus page
-- Nothing here is a guess. A wrong pin sends a family to the wrong stadium, which
-- is the failure this project spent 2026-08-16 fixing in the Print View PDF.
--
-- ── SCOPE: 2026-27 AND EVENTS ONLY ──
-- Last season's rows (2025-26) are matched only where the venue already exists in
-- this seed. Eight 2025-26 venues are deliberately NOT seeded - House Park, Hutto
-- HS, Manor HS, Memorial Stadium, Monroe Stadium, The Pfield, Vandegrift HS,
-- Weiss HS - because nobody navigates to last season's away games and inventing
-- pins for them is unpaid risk. Those rows keep venue_id NULL and render exactly
-- as they do today. The assertion below is scoped to 2026-27 accordingly.
--
-- ⚠️ ALIASES ARE A REAL HAZARD. The same place is already spelled two ways across
-- seasons: 'Gupton' (2026-27) vs 'Gupton Stadium' (2025-26), 'Dragon Stadium' vs
-- 'Round Rock HS', 'Chaparral' vs 'Chaparral Stadium'. This migration maps the
-- known aliases, but going forward the answer is to SET venue_id, not to type the
-- location string and hope it matches. `location` stays as the display label
-- (which is why 'Maverick Stadium' still reads "Maverick Stadium" and not "McNeil
-- High School") - the venue supplies the link and the address, nothing else.

begin;

create table if not exists venues (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  address    text not null,
  maps_url   text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table venues is
  'Physical places games and events happen. One row per place; games.venue_id / '
  'events.venue_id reference it. `address` is what the ICS feed emits so a phone '
  'can navigate; `maps_url` is what the site links to.';

alter table games  add column if not exists venue_id uuid references venues(id);
alter table events add column if not exists venue_id uuid references venues(id);

comment on column games.venue_id is
  'The place this game is played. Set this rather than typing a location string '
  'and hoping it matches a venue name - `location` is only the display label.';
comment on column events.location_url is
  'DEPRECATED (migration 134). Use venue_id; the venue owns the link. Kept only '
  'so no historical row loses data. Do not set on new rows.';

grant select on venues to anon, authenticated;
grant insert, update, delete on venues to authenticated;

alter table venues enable row level security;

create policy "Anyone reads venues" on venues
  for select to anon using (true);
create policy "Authenticated read venues" on venues
  for select to authenticated using (true);
create policy "Content admins write venues" on venues
  for insert to authenticated with check (current_user_has_role('content_admin'));
create policy "Content admins update venues" on venues
  for update to authenticated using (current_user_has_role('content_admin'))
  with check (current_user_has_role('content_admin'));
create policy "Content admins delete venues" on venues
  for delete to authenticated using (current_user_has_role('content_admin'));

-- ── the places ──────────────────────────────────────────────────────────────
insert into venues (name, address, maps_url) values
  ('McNeil High School',
   '5720 McNeil Drive, Austin, TX 78729',
   'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729'),
  ('Kelly Reeves Athletic Complex',
   '10211 W Parmer Lane, Austin, TX 78717',
   'https://maps.google.com/?q=10211+W+Parmer+Lane+Austin+TX+78717'),
  ('Round Rock High School Dragon Stadium',
   '201 Deep Wood Drive, Round Rock, TX 78681',
   'https://www.google.com/maps/place/Round+Rock+High+School+Dragon+Stadium/@30.5071484,-97.6961314,17z/data=!3m1!4b1!4m6!3m5!1s0x8644d1f4d7afa049:0x2acf18eb0c86d57c!8m2!3d30.5071207!4d-97.6953804!16s%2Fg%2F1thw_vbd'),
  ('Toney Burger Stadium',
   '3200 Jones Road, Austin, TX',
   'https://www.google.com/maps/place/Burger+Stadium/@30.2305155,-97.8123217,16z/data=!3m1!4b1!4m6!3m5!1s0x865b4b144a13f911:0xf29b3922fac942ba!8m2!3d30.2305155!4d-97.8097468!16s%2Fm%2F0k0bh48'),
  ('Gupton Stadium',
   '200 Gupton Way Drive, Cedar Park, TX 78613',
   'https://maps.google.com/?q=200+Gupton+Way+Drive+Cedar+Park+TX+78613'),
  ('Chaparral Stadium',
   '4100 Westbank Drive, Austin, TX 78746',
   'https://maps.google.com/?q=4100+Westbank+Drive+Austin+TX+78746'),
  ('James Bowie High School',
   '4103 W Slaughter Lane, Austin, TX 78749',
   'https://maps.google.com/?q=4103+W+Slaughter+Lane+Austin+TX+78749'),
  ('Lake Belton High School',
   '9809 Prairie View Road, Temple, TX 76502',
   'https://maps.google.com/?q=9809+Prairie+View+Road+Temple+TX+76502'),
  ('Rouse High School',
   '1222 Raider Way, Leander, TX 78641',
   'https://maps.google.com/?q=1222+Raider+Way+Leander+TX+78641'),
  ('Vista Ridge High School',
   '200 S Vista Ridge Boulevard, Cedar Park, TX 78613',
   'https://maps.google.com/?q=200+S+Vista+Ridge+Boulevard+Cedar+Park+TX+78613'),
  ('Lake Travis High School',
   '3324 Ranch Road 620 S, Austin, TX 78738',
   'https://maps.google.com/?q=3324+Ranch+Road+620+S+Austin+TX+78738'),
  ('Cedar Ridge High School',
   '2801 Gattis School Road, Round Rock, TX 78664',
   'https://maps.google.com/?q=2801+Gattis+School+Road+Round+Rock+TX+78664'),
  ('Stony Point High School',
   '1801 Tiger Trail, Round Rock, TX 78664',
   'https://maps.google.com/?q=1801+Tiger+Trail+Round+Rock+TX+78664'),
  ('Westlake High School',
   '4100 Westbank Drive, Austin, TX 78746',
   'https://maps.google.com/?q=4100+Westbank+Drive+Austin+TX+78746'),
  ('Westwood High School',
   '12400 Mellow Meadow Drive, Austin, TX 78750',
   'https://maps.google.com/?q=12400+Mellow+Meadow+Drive+Austin+TX+78750'),
  ('Phil''s Ice House (183)',
   '13265 N US-183, Austin, TX 78750',
   'https://maps.google.com/?q=13265+N+US-183+Austin+TX+78750'),
  ('Morningside Pool (Avery Ranch)',
   '10121 Morgan Creek Drive, Austin, TX 78717',
   'https://maps.google.com/?q=10121+Morgan+Creek+Dr+Austin+TX+78717')
on conflict (name) do nothing;

-- ── backfill: location string -> venue ──────────────────────────────────────
with mapping (loc, venue_name) as (values
  -- 2026-27 games
  ('Maverick Stadium',                   'McNeil High School'),
  ('KRAC',                               'Kelly Reeves Athletic Complex'),
  ('Dragon Stadium',                     'Round Rock High School Dragon Stadium'),
  ('Burger Stadium',                     'Toney Burger Stadium'),
  ('Gupton',                             'Gupton Stadium'),
  ('Chaparral',                          'Chaparral Stadium'),
  ('Bowie HS',                           'James Bowie High School'),
  ('Lake Belton HS',                     'Lake Belton High School'),
  ('Rouse HS',                           'Rouse High School'),
  ('Vista Ridge HS',                     'Vista Ridge High School'),
  ('Lake Travis HS',                     'Lake Travis High School'),
  ('Cedar Ridge HS',                     'Cedar Ridge High School'),
  ('Stony Point HS',                     'Stony Point High School'),
  ('Westlake HS',                        'Westlake High School'),
  ('Westwood HS',                        'Westwood High School'),
  -- 2025-26 spellings of the same places (see the alias warning above)
  ('Gupton Stadium',                     'Gupton Stadium'),
  ('Round Rock HS',                      'Round Rock High School Dragon Stadium')
)
update games g
   set venue_id = v.id
  from mapping m
  join venues v on v.name = m.venue_name
 where g.location = m.loc
   and g.venue_id is null;

with mapping (loc, venue_name) as (values
  ('McNeil High School',                 'McNeil High School'),
  ('McNeil High School Stadium',         'McNeil High School'),
  ('McNeil High School Cafeteria',       'McNeil High School'),
  ('Team Room G204, McNeil High School', 'McNeil High School'),
  ('Phil’s Ice House (183)',             'Phil''s Ice House (183)'),
  ('Morningside Pool (Avery Ranch)',     'Morningside Pool (Avery Ranch)')
)
update events e
   set venue_id = v.id
  from mapping m
  join venues v on v.name = m.venue_name
 where e.location = m.loc
   and e.venue_id is null;

-- One source for the link: the venue now owns it.
update events set location_url = null where venue_id is not null;

-- ── assertions ──────────────────────────────────────────────────────────────
do $$
declare n int; leftover text;
begin
  select count(*) into n from venues;
  if n < 17 then raise exception 'expected at least 17 venues, got %', n; end if;

  -- Every CURRENT-season game that names a place must resolve to one.
  select count(*), string_agg(distinct location, ', ')
    into n, leftover
    from games
   where year = '2026-27' and location is not null and venue_id is null;
  if n > 0 then
    raise exception '% 2026-27 game rows have an unmatched venue: %', n, leftover;
  end if;

  -- Same for every event that names a place.
  select count(*), string_agg(distinct location, ', ')
    into n, leftover
    from events
   where coalesce(location, '') <> '' and venue_id is null;
  if n > 0 then
    raise exception '% event rows have an unmatched venue: %', n, leftover;
  end if;

  -- No event may carry a link in two places any more.
  select count(*) into n from events where venue_id is not null and location_url is not null;
  if n <> 0 then raise exception '% events still carry a stale location_url', n; end if;

  -- Last season is expected to have leftovers; say how many rather than failing.
  select count(*), string_agg(distinct location, ', ')
    into n, leftover
    from games
   where year <> '2026-27' and location is not null and venue_id is null;
  raise notice '% archived (non-2026-27) game rows have no venue: %', n, coalesce(leftover, 'none');
end $$;

commit;

-- Verification:
--   select v.name, count(g.id) from venues v left join games g on g.venue_id = v.id
--    where g.year = '2026-27' group by 1 order by 2 desc;
--   -- and the gap check to run after ANY new game is added:
--   select distinct location from games where year = '2026-27' and venue_id is null
--     and location is not null;

-- ===
-- db/migrations/135_venue_pins_from_jeremy.sql
-- ===

-- 135_venue_pins_from_jeremy.sql
--
-- Three verified Google Maps place pins from Jeremy, 2026-08-16, replacing the
-- address-search links migration 134 built from district web pages:
--   Maverick Stadium               (18 games this season - the most-used venue)
--   Kelly Reeves Athletic Complex  (5)
--   Gupton Stadium                 (2)
--
-- A `?q=<address>` link drops you at the street address; these are the actual
-- place pins, which is the difference between "the school" and "the stadium you
-- park at". Jeremy is checking the remaining venues; those keep their district
-- addresses until he does.
--
-- ⚠️ MAVERICK STADIUM BECOMES ITS OWN VENUE - it is NOT the campus pin.
-- 134 folded 'Maverick Stadium' into the McNeil High School venue on the theory
-- that the stadium sits on campus and the campus address was the best available
-- answer. Jeremy's link disproves the premise: the stadium pin is at
-- 30.4503017,-97.7302712 while the campus pin is 30.4498039,-97.7321648 - about
-- 200 m apart, different entrances. So this splits them:
--   games   location = 'Maverick Stadium'           -> Maverick Stadium (new)
--   events  location = 'McNeil High School Stadium' -> Maverick Stadium (new)
--   events  location = 'McNeil High School' / Cafeteria / Team Room G204
--                                                   -> McNeil High School (campus)
-- The events move is an inference worth stating: 'McNeil High School Stadium' is
-- the same physical place as 'Maverick Stadium' (it is where Meet the Mavs is
-- held), so it gets the stadium pin. If that is ever wrong, repoint those two
-- rows - the display label does not change either way.
--
-- Both venues keep the SAME street address (5720 McNeil Drive) because that is
-- what Google itself associates with the stadium pin - see the `!2s5720+McNeil+
-- Dr,+Austin,+TX+78729` segment inside the URL. The ICS therefore emits
-- "Maverick Stadium, 5720 McNeil Drive, Austin, TX 78729", which navigates
-- correctly, while the on-site link goes to the precise pin.
--
-- URL hygiene: the `?entry=ttu&g_ep=...` tail on a pasted Maps URL is session
-- junk and is stripped. What remains is the place path plus the data segment
-- carrying the feature id and coordinates.
--
-- Verification note: these were NOT confirmed by fetching them - google.com/maps
-- serves a generic "Google Maps" shell to a non-browser client, so a fetch proves
-- nothing beyond a 200. What is checkable is inside the URLs themselves: each
-- carries a place name in its path and coordinates that sit where that place
-- should be. Jeremy opened all three.

begin;

-- The new, distinct stadium pin.
insert into venues (name, address, maps_url) values
  ('Maverick Stadium',
   '5720 McNeil Drive, Austin, TX 78729',
   'https://www.google.com/maps/place/Maverick+Stadium/@30.4493128,-97.7374311,16z/data=!4m15!1m8!3m7!1s0x8644cda571be6383:0x55cd609971b1d5e8!2s5720+McNeil+Dr,+Austin,+TX+78729!3b1!8m2!3d30.4498039!4d-97.7321648!16s%2Fg%2F11bw436jbr!3m5!1s0x8644cdafb123bf1f:0x87fbeafd2a7f6b9b!8m2!3d30.4503017!4d-97.7302712!16s%2Fg%2F11p0w489y6')
on conflict (name) do update set maps_url = excluded.maps_url, updated_at = now();

update venues
   set maps_url = 'https://www.google.com/maps/place/Kelly+Reeves+Athletic+Complex/@30.4934448,-97.777533,17z/data=!4m15!1m8!3m7!1s0x865b32b28458d587:0xb05997bbdeea8e25!2s10211+W+Parmer+Ln,+Austin,+TX+78717!3b1!8m2!3d30.4934448!4d-97.7749581!16s%2Fg%2F11bw4n56bs!3m5!1s0x8644d2b099574bed:0xccc7137bc54362d0!8m2!3d30.4926179!4d-97.7751922!16s%2Fg%2F1vvdvlwd',
       updated_at = now()
 where name = 'Kelly Reeves Athletic Complex';

update venues
   set maps_url = 'https://www.google.com/maps/place/John+Gupton+Stadium/@30.5157472,-97.7937186,17z/data=!4m15!1m8!3m7!1s0x865b2d2e7a93de05:0x5341c426abf48333!2s200+Gupton+Way+Dr,+Cedar+Park,+TX+78613!3b1!8m2!3d30.5157472!4d-97.7911437!16s%2Fg%2F11c4n0yrcw!3m5!1s0x865b2d300a63cf9b:0x71749e8ca8d3b2bc!8m2!3d30.5151663!4d-97.791966!16s%2Fg%2F1tq4rhp8',
       updated_at = now()
 where name = 'Gupton Stadium';

-- Repoint everything that means "the stadium", every season.
update games
   set venue_id = (select id from venues where name = 'Maverick Stadium')
 where location = 'Maverick Stadium';

update events
   set venue_id = (select id from venues where name = 'Maverick Stadium')
 where location = 'McNeil High School Stadium';

-- ── assertions ──────────────────────────────────────────────────────────────
do $$
declare n int; stadium uuid; campus uuid;
begin
  select id into stadium from venues where name = 'Maverick Stadium';
  select id into campus  from venues where name = 'McNeil High School';
  if stadium is null or campus is null then
    raise exception 'stadium and campus venues must both exist';
  end if;
  if stadium = campus then raise exception 'stadium and campus must be distinct rows'; end if;

  select count(*) into n from games where location = 'Maverick Stadium' and venue_id = stadium;
  if n <> 35 then raise exception 'expected 35 Maverick Stadium games (all seasons), got %', n; end if;

  select count(*) into n from games where location = 'Maverick Stadium' and venue_id = campus;
  if n <> 0 then raise exception '% stadium games still point at the campus pin', n; end if;

  select count(*) into n from events where location = 'McNeil High School Stadium' and venue_id = stadium;
  if n <> 2 then raise exception 'expected 2 stadium events, got %', n; end if;

  -- Campus-proper events must NOT have moved.
  select count(*) into n from events
   where location in ('McNeil High School', 'McNeil High School Cafeteria',
                      'Team Room G204, McNeil High School')
     and venue_id = campus;
  if n <> 12 then raise exception 'expected 12 campus events, got %', n; end if;

  -- Every pin Jeremy supplied must be a place URL, not an address search.
  select count(*) into n from venues
   where name in ('Maverick Stadium', 'Kelly Reeves Athletic Complex', 'Gupton Stadium')
     and maps_url like 'https://www.google.com/maps/place/%';
  if n <> 3 then raise exception 'expected 3 place-pin venues, got %', n; end if;

  -- No pasted-session junk should ever land in a stored URL.
  select count(*) into n from venues where maps_url like '%entry=ttu%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs still carry Maps session parameters', n; end if;
end $$;

commit;

-- Verification:
--   select v.name, v.maps_url, count(g.id) games
--     from venues v left join games g on g.venue_id = v.id and g.year = '2026-27'
--    group by 1,2 order by 3 desc;

-- ===
-- db/migrations/136_lake_belton_pin.sql
-- ===

-- 136_lake_belton_pin.sql
--
-- Lake Belton High School: exact pin from Jeremy, 2026-08-16, replacing 134's
-- address-search link, which he reported landed "in the middle of a road".
-- It did. Checked independently before writing this:
--   134's link      '9809 Prairie View Road, Temple, TX 76502'
--                   -> geocodes to a ROAD CENTERLINE with no house number,
--                      920 m from the school
--   Jeremy's pin    31.143741, -97.441674
--                   -> reverse-geocodes to house number 9809 on FM 2483
--
-- ⚠️ THE ADDRESS STRING CHANGES TOO, and that is the substantive half of this
-- migration. Belton ISD publishes the campus as both "9809 Prairie View Road"
-- and "9809 FM 2483"; only the FM 2483 form geocodes to the building. The
-- address is not decoration - the ICS feed emits it as LOCATION, and a phone
-- geocoding "Prairie View Road" would send a subscriber to the same wrong stretch
-- of road the old link did. Fixing the maps_url without fixing the address would
-- have left the calendar broken and looked done.
--
-- ── ON SHORT LINKS ──
-- Jeremy sent https://maps.app.goo.gl/L5biefyVV5WVPsPF9. It is EXPANDED here
-- rather than stored. A shortener is opaque - nobody reviewing this file, or
-- diffing it in a year, can tell where it points - and it adds a second service
-- that has to stay up for a link on the site to work (Google turned down the
-- general goo.gl shortener in 2025; maps.app.goo.gl survives, but there is no
-- reason to depend on it). Same reasoning as the Venmo QR sign in the
-- BoosterClub project: never ship an opaque pointer you cannot read back.
-- Resolved with `curl -I` and stored in the documented Maps URLs API form.
--
-- Note this pin is a COORDINATE SEARCH, not a named place like the Maverick
-- Stadium / KRAC / Gupton pins in migration 135. That is fine and arguably more
-- precise - it is an exact point rather than Google's centroid for a named
-- feature - but it means the map opens without a place card.

begin;

update venues
   set maps_url = 'https://www.google.com/maps/search/?api=1&query=31.143741%2C-97.441674',
       address  = '9809 FM 2483, Temple, TX 76502',
       updated_at = now()
 where name = 'Lake Belton High School';

do $$
declare n int;
begin
  select count(*) into n from venues
   where name = 'Lake Belton High School'
     and address = '9809 FM 2483, Temple, TX 76502'
     and maps_url like '%31.143741%2C-97.441674';
  if n <> 1 then raise exception 'Lake Belton venue not updated as expected'; end if;

  -- No stored venue URL may be a shortener: opaque, and a second dependency.
  select count(*) into n from venues where maps_url like '%goo.gl%';
  if n <> 0 then raise exception '% venue URLs are shortened links', n; end if;

  -- Still no pasted Maps session junk (carried forward from 135).
  select count(*) into n from venues where maps_url like '%entry=tt%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs carry Maps session parameters', n; end if;
end $$;

commit;

-- /schedule/games/* and /events read at request time: live with no deploy.

-- ===
-- db/migrations/137_venue_coordinates.sql
-- ===

-- 137_venue_coordinates.sql
--
-- Coordinates on venues, so the ICS feed can emit a GEO property (RFC 5545
-- § 3.8.1.6) alongside LOCATION. Plus Chaparral Stadium's real pin from Jeremy.
--
-- ── WHY ──
-- The calendar is the weakest surface for precision and the one people rely on
-- when they are already driving. A subscribed VEVENT can only carry LOCATION,
-- a text string that the phone geocodes itself - which is exactly how Lake
-- Belton sent people to a road centerline 920 m from the school (migration 136).
-- GEO carries the point itself, so clients that support it stop guessing.
--
-- ⚠️ GEO IS NEVER GUESSED. Coordinates are set ONLY for venues where a human
-- opened the pin: the five place links Jeremy sent (Maverick Stadium, KRAC,
-- Gupton, Dragon Stadium, Burger), the Lake Belton dropped pin, and Chaparral
-- below. Every other venue keeps latitude/longitude NULL and the feed omits GEO
-- for it, leaving today's behaviour (the client geocodes the address) untouched.
--
-- Geocoding the remaining addresses to fill the columns would have been easy and
-- WRONG: it would stamp unverified coordinates into subscribers' calendars with
-- the authority of a precise point, which is a worse failure than the vague
-- address it replaced. The whole reason this column exists is that Jeremy found
-- two street addresses in a row that pointed at the wrong place. NULL is the
-- honest value until someone opens the pin.
--
-- Coordinates are lifted from the `!3m5!…!8m2!3d<lat>!4d<lon>` segment of each
-- stored Maps URL - the SELECTED place, not the `!1m8!3m7…` segment earlier in
-- the same URL, which is the associated street address and is a different point.
-- On the Chaparral URL those two differ by ~260 m.
--
-- ── CHAPARRAL SPLITS FROM THE WESTLAKE CAMPUS ──
-- Same shape as Maverick Stadium in migration 135. 134 gave 'Chaparral Stadium'
-- and 'Westlake High School' the same 4100 Westbank Dr address search, because
-- the stadium is on the campus. Jeremy's link shows the stadium pin is
-- 30.2776477,-97.813297 and the campus address pin is 30.2752887,-97.8130021.
-- Varsity plays at Chaparral; the JV and freshman rows say 'Westlake HS' and may
-- well be a different field on the same campus, which is exactly the away-field
-- variance Jeremy flagged - so the two venues stay separate rows and only
-- Chaparral gets the verified pin.

begin;

alter table venues add column if not exists latitude  double precision;
alter table venues add column if not exists longitude double precision;

comment on column venues.latitude is
  'Decimal degrees, NULL unless a human has opened the pin. Emitted as the ICS '
  'GEO property. Never fill this by geocoding an address - an unverified point '
  'presented as exact is worse than no point at all.';

update venues set
  maps_url = 'https://www.google.com/maps/place/Chaparral+Stadium%2FEbbie+Neptune+Field/@30.277489,-97.8138113,692m/data=!3m1!1e3!4m15!1m8!3m7!1s0x865b4a8e09cd721f:0xc89a7e416cdbb18e!2s4100+Westbank+Dr,+Austin,+TX+78746!3b1!8m2!3d30.2752887!4d-97.8130021!16s%2Fg%2F11bw3gczyw!3m5!1s0x865b4a915eba75c3:0x6d7187a81942de97!8m2!3d30.2776477!4d-97.813297!16s%2Fm%2F0pyw91j',
  updated_at = now()
 where name = 'Chaparral Stadium';

update venues set latitude = 30.4503017, longitude = -97.7302712, updated_at = now()
 where name = 'Maverick Stadium';
update venues set latitude = 30.4926179, longitude = -97.7751922, updated_at = now()
 where name = 'Kelly Reeves Athletic Complex';
update venues set latitude = 30.5151663, longitude = -97.7919660, updated_at = now()
 where name = 'Gupton Stadium';
update venues set latitude = 30.5071207, longitude = -97.6953804, updated_at = now()
 where name = 'Round Rock High School Dragon Stadium';
update venues set latitude = 30.2305155, longitude = -97.8097468, updated_at = now()
 where name = 'Toney Burger Stadium';
update venues set latitude = 31.1437410, longitude = -97.4416740, updated_at = now()
 where name = 'Lake Belton High School';
update venues set latitude = 30.2776477, longitude = -97.8132970, updated_at = now()
 where name = 'Chaparral Stadium';

do $$
declare n int;
begin
  select count(*) into n from venues where latitude is not null;
  if n <> 7 then raise exception 'expected 7 venues with coordinates, got %', n; end if;

  -- Lat and lon are set together or not at all; half a coordinate is a bug.
  select count(*) into n from venues
   where (latitude is null) <> (longitude is null);
  if n <> 0 then raise exception '% venues have only half a coordinate', n; end if;

  -- Central Texas sanity box. Catches a swapped lat/lon or a dropped minus sign,
  -- which is the realistic way a coordinate goes wrong by hand.
  select count(*) into n from venues
   where latitude is not null
     and (latitude not between 29.5 and 31.5 or longitude not between -98.5 and -97.0);
  if n <> 0 then raise exception '% venue coordinates are outside Central Texas', n; end if;

  -- Every venue carrying coordinates must also carry the pin they came from.
  select count(*) into n from venues
   where latitude is not null
     and maps_url not like 'https://www.google.com/maps/%';
  if n <> 0 then raise exception '% venues have coordinates but no place pin', n; end if;
end $$;

commit;

-- Verification:
--   select name, latitude, longitude from venues where latitude is not null order by name;

-- ===
-- db/migrations/138_cavalier_stadium.sql
-- ===

-- 138_cavalier_stadium.sql
--
-- Lake Travis: Cavalier Stadium pin from Jeremy, 2026-08-16.
--
-- Third stadium/campus split in a row, and the pattern is now established beyond
-- doubt: the pin he sent is 30.3248488,-97.9680765 while the campus address pin
-- inside the SAME URL (3324 Ranch Rd 620 S) is 30.3282475,-97.9666167 - about
-- 480 m apart. Maverick Stadium was ~200 m from its campus pin (135) and
-- Chaparral ~260 m (137). Assume they differ until shown otherwise.
--
-- So Cavalier Stadium is its own venue and the one game that plays there is
-- repointed. 'Lake Travis High School' (the campus, with the district address
-- and no coordinates) stays in the table but is now referenced by nothing - kept
-- deliberately, because the JV/freshman away fields vary and a future row may
-- genuinely mean the campus rather than the varsity stadium. An unused venue row
-- costs nothing; re-deriving a deleted one costs a lookup.
--
-- ⚠️ Only ONE game currently plays here (JV, Wed Sep 23) - varsity hosts Lake
-- Travis at KRAC and the freshmen host at Maverick Stadium. That single row is
-- an AWAY JV game, and Jeremy has flagged that JV and freshman away fields vary,
-- so this pin is "the stadium at Lake Travis", not proof that JV plays in it. If
-- it turns out they play a side field, add that venue and repoint this one row.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Cavalier Stadium',
   '3324 Ranch Road 620 S, Austin, TX 78738',
   'https://www.google.com/maps/place/Cavalier+Stadium/@30.3240184,-97.9696299,588m/data=!3m1!1e3!4m15!1m8!3m7!1s0x865b382c58a80363:0x336b14128be316f7!2s3324+Ranch+Rd+620+S,+Austin,+TX+78738!3b1!8m2!3d30.3282475!4d-97.9666167!16s%2Fg%2F11c0px86wt!3m5!1s0x865b3831d8480283:0xf7d2f43ae250066f!8m2!3d30.3248488!4d-97.9680765!16s%2Fg%2F1wg5yf21',
   30.3248488, -97.9680765)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Cavalier Stadium')
 where location = 'Lake Travis HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Cavalier Stadium';
  if n <> 1 then raise exception 'expected 1 game at Cavalier Stadium, got %', n; end if;

  select count(*) into n from games where location = 'Lake Travis HS' and venue_id is null;
  if n <> 0 then raise exception '% Lake Travis games lost their venue', n; end if;

  -- Carry forward every rule from 136 + 137 on the whole table, so a later
  -- migration cannot quietly break them.
  select count(*) into n from venues
   where maps_url like '%goo.gl%' or maps_url like '%entry=tt%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs are shortened or carry session junk', n; end if;

  select count(*) into n from venues where (latitude is null) <> (longitude is null);
  if n <> 0 then raise exception '% venues have only half a coordinate', n; end if;

  select count(*) into n from venues
   where latitude is not null
     and (latitude not between 29.5 and 31.5 or longitude not between -98.5 and -97.0);
  if n <> 0 then raise exception '% venue coordinates are outside Central Texas', n; end if;
end $$;

commit;

-- /schedule/games/* and /events read at request time: live with no deploy.

-- ===
-- db/migrations/139_stony_point_tiger_stadium.sql
-- ===

-- 139_stony_point_tiger_stadium.sql
--
-- Stony Point: Tiger Stadium pin from Jeremy, 2026-08-16. Fourth stadium/campus
-- split; the pin is 30.5304036,-97.6642866 and the campus address pin inside the
-- same URL (1801 Tiger Trail) is 30.5291345,-97.6609148, ~350 m apart.
--
-- Running tally of pin-vs-campus distance, which is why this is now the default
-- assumption rather than a surprise:
--   Maverick Stadium   ~200 m (135)
--   Chaparral          ~260 m (137)
--   Cavalier           ~480 m (138)
--   Tiger Stadium      ~350 m (this one)
--
-- Both seasons' rows move (2025-26 JV and 2026-27 JV) - same treatment the
-- 'Maverick Stadium' rows got in 135. The archived row is not worth a second
-- venue and the place has not moved.
--
-- 'Stony Point High School' (campus, district address, no coordinates) stays in
-- the table unreferenced, for the same reason 138 kept the Lake Travis campus
-- row: away fields vary and a future row may mean the campus.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Stony Point Tiger Stadium',
   '1801 Tiger Trail, Round Rock, TX 78664',
   'https://www.google.com/maps/place/Stony+Point+Tiger+Stadium/@30.5304751,-97.6642963,429m/data=!3m1!1e3!4m15!1m8!3m7!1s0x8644d1a95ddb5b4d:0xdf7c6cd9c4b0eae7!2s1801+Tiger+Trail,+Round+Rock,+TX+78664!3b1!8m2!3d30.5291345!4d-97.6609148!16s%2Fg%2F11bw3zlw8g!3m5!1s0x8644d13a7999f74d:0x1264a8be29585b53!8m2!3d30.5304036!4d-97.6642866!16s%2Fg%2F11tk47mzh9',
   30.5304036, -97.6642866)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Stony Point Tiger Stadium')
 where location = 'Stony Point HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Stony Point Tiger Stadium';
  if n <> 2 then raise exception 'expected 2 games at Tiger Stadium (both seasons), got %', n; end if;

  select count(*) into n from games where location = 'Stony Point HS' and venue_id is null;
  if n <> 0 then raise exception '% Stony Point games lost their venue', n; end if;

  select count(*) into n from venues
   where maps_url like '%goo.gl%' or maps_url like '%entry=tt%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs are shortened or carry session junk', n; end if;

  select count(*) into n from venues where (latitude is null) <> (longitude is null);
  if n <> 0 then raise exception '% venues have only half a coordinate', n; end if;

  select count(*) into n from venues
   where latitude is not null
     and (latitude not between 29.5 and 31.5 or longitude not between -98.5 and -97.0);
  if n <> 0 then raise exception '% venue coordinates are outside Central Texas', n; end if;
end $$;

commit;

-- ===
-- db/migrations/140_charles_rouse_stadium.sql
-- ===

-- 140_charles_rouse_stadium.sql
--
-- Rouse: Charles Rouse Stadium pin from Jeremy, 2026-08-16. Fifth stadium/campus
-- split; pin 30.5690341,-97.8194206 vs the campus address pin in the same URL
-- (1222 Raider Way) at 30.5719732,-97.8205576, ~340 m apart.
--
-- Both rows here are FRESHMAN games (Blue 5:00, Green 6:30, Thu Sep 10) - the
-- first time a verified stadium pin lands on freshman rows rather than varsity
-- or JV. Jeremy has been explicit that freshman and JV away fields vary, so this
-- is "the stadium at Rouse" and not proof the freshmen play in it. It is still
-- strictly better than the campus address, which is 340 m from the stadium and
-- was never verified either. Repoint if better specifics arrive.
--
-- 'Rouse High School' (campus, district address, no coordinates) stays in the
-- table unreferenced, same as the Lake Travis and Stony Point campus rows.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Charles Rouse Stadium',
   '1222 Raider Way, Leander, TX 78641',
   'https://www.google.com/maps/place/Charles+Rouse+Stadium/@30.5690449,-97.8202182,194m/data=!3m1!1e3!4m15!1m8!3m7!1s0x865b2b7c557294af:0x850a0cddfe02943e!2s1222+Raider+Way,+Leander,+TX+78641!3b1!8m2!3d30.5719732!4d-97.8205576!16s%2Fg%2F11rp1yvtfm!3m5!1s0x865b2b939c10e7b7:0x496208446df75b27!8m2!3d30.5690341!4d-97.8194206!16s%2Fg%2F11gnsckwc7',
   30.5690341, -97.8194206)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Charles Rouse Stadium')
 where location = 'Rouse HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Charles Rouse Stadium';
  if n <> 2 then raise exception 'expected 2 games at Charles Rouse Stadium, got %', n; end if;

  select count(*) into n from games where location = 'Rouse HS' and venue_id is null;
  if n <> 0 then raise exception '% Rouse games lost their venue', n; end if;

  select count(*) into n from venues
   where maps_url like '%goo.gl%' or maps_url like '%entry=tt%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs are shortened or carry session junk', n; end if;

  select count(*) into n from venues where (latitude is null) <> (longitude is null);
  if n <> 0 then raise exception '% venues have only half a coordinate', n; end if;

  select count(*) into n from venues
   where latitude is not null
     and (latitude not between 29.5 and 31.5 or longitude not between -98.5 and -97.0);
  if n <> 0 then raise exception '% venue coordinates are outside Central Texas', n; end if;
end $$;

commit;

-- ===
-- db/migrations/141_vista_ridge_football_field.sql
-- ===

-- 141_vista_ridge_football_field.sql
--
-- Vista Ridge: football field pin from Jeremy, 2026-08-16. Sixth split; pin
-- 30.5192122,-97.7873188 vs the campus at 30.5165045,-97.7878702, ~300 m apart.
--
-- ⚠️ THIS URL IS SHAPED DIFFERENTLY from the previous five and the difference
-- matters when reading coordinates out by hand. The earlier links carried a
-- STREET ADDRESS in the `!1m8!3m7…!2s<address>` segment; this one carries a
-- PLACE, `!2sVista+Ridge+High+School`, with its own coordinates. The rule is
-- unchanged and is about position, not content: the pin is always the LAST
-- `!3m5!…!8m2!3d<lat>!4d<lon>` group, the selected feature. The earlier group is
-- context Google threw in, whatever its type.
--
-- Because that segment is a place rather than an address, this URL supplies NO
-- street address, so the venue keeps Leander ISD's published one. That is fine:
-- `address` feeds the ICS LOCATION text and `latitude/longitude` feed GEO, and
-- only the latter needs to be exact.
--
-- Three rows move, including a 2025-26 JV game - same all-seasons treatment as
-- every venue since 135. The 2026-27 pair are freshman Blue and Green, so the
-- Rouse caveat applies: this is "the field at Vista Ridge", not proof the
-- freshmen play on it.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Vista Ridge Football Field',
   '200 S Vista Ridge Boulevard, Cedar Park, TX 78613',
   'https://www.google.com/maps/place/Vista+Ridge+Football+Field/@30.519268,-97.7895439,793m/data=!3m1!1e3!4m14!1m7!3m6!1s0x865b2d2c6700680b:0x36319648a550950d!2sVista+Ridge+High+School!8m2!3d30.5165045!4d-97.7878702!16zL20vMDl6NHR4!3m5!1s0x865b2dbedc7b71f5:0xa5c5b56470d0bb53!8m2!3d30.5192122!4d-97.7873188!16s%2Fg%2F11js4mz_yd',
   30.5192122, -97.7873188)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Vista Ridge Football Field')
 where location = 'Vista Ridge HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Vista Ridge Football Field';
  if n <> 3 then raise exception 'expected 3 games at Vista Ridge (both seasons), got %', n; end if;

  select count(*) into n from games where location = 'Vista Ridge HS' and venue_id is null;
  if n <> 0 then raise exception '% Vista Ridge games lost their venue', n; end if;

  select count(*) into n from venues
   where maps_url like '%goo.gl%' or maps_url like '%entry=tt%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs are shortened or carry session junk', n; end if;

  select count(*) into n from venues where (latitude is null) <> (longitude is null);
  if n <> 0 then raise exception '% venues have only half a coordinate', n; end if;

  select count(*) into n from venues
   where latitude is not null
     and (latitude not between 29.5 and 31.5 or longitude not between -98.5 and -97.0);
  if n <> 0 then raise exception '% venue coordinates are outside Central Texas', n; end if;
end $$;

commit;

-- ===
-- db/migrations/142_cedar_ridge_stadium.sql
-- ===

-- 142_cedar_ridge_stadium.sql
--
-- Cedar Ridge: football stadium pin from Jeremy, 2026-08-16. Seventh split; pin
-- 30.4926553,-97.6377619 vs the campus address pin in the same URL (2801 Gattis
-- School Rd) at 30.4948292,-97.6421454, ~450 m apart.
--
-- Four rows move, two per season, all FRESHMAN Blue + Green. Same caveat as
-- Rouse and Vista Ridge: this is the stadium at Cedar Ridge, not proof the
-- freshmen play in it. 'Cedar Ridge High School' (campus) stays unreferenced.
--
-- Note Cedar Ridge is an RRISD school, so its rows may move to a shared district
-- facility in a future season the way McNeil's own varsity home games sit at KRAC
-- rather than Maverick Stadium. If that happens the fix is repointing rows, not
-- editing this venue - the stadium itself has not moved.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Cedar Ridge High School Football Stadium',
   '2801 Gattis School Road, Round Rock, TX 78664',
   'https://www.google.com/maps/place/Cedar+Ridge+High+School+Football+Stadium/@30.4923251,-97.6385667,200m/data=!3m1!1e3!4m15!1m8!3m7!1s0x8644d025c69c508f:0xae9add38c6a1c93e!2s2801+Gattis+School+Rd,+Round+Rock,+TX+78664!3b1!8m2!3d30.4948292!4d-97.6421454!16s%2Fg%2F11p_836m1c!3m5!1s0x8644d1048f24f785:0x2ffd06061a5c04d1!8m2!3d30.4926553!4d-97.6377619!16s%2Fg%2F11t_m4j9mn',
   30.4926553, -97.6377619)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Cedar Ridge High School Football Stadium')
 where location = 'Cedar Ridge HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Cedar Ridge High School Football Stadium';
  if n <> 4 then raise exception 'expected 4 games at Cedar Ridge (both seasons), got %', n; end if;

  select count(*) into n from games where location = 'Cedar Ridge HS' and venue_id is null;
  if n <> 0 then raise exception '% Cedar Ridge games lost their venue', n; end if;

  select count(*) into n from venues
   where maps_url like '%goo.gl%' or maps_url like '%entry=tt%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs are shortened or carry session junk', n; end if;

  select count(*) into n from venues where (latitude is null) <> (longitude is null);
  if n <> 0 then raise exception '% venues have only half a coordinate', n; end if;

  select count(*) into n from venues
   where latitude is not null
     and (latitude not between 29.5 and 31.5 or longitude not between -98.5 and -97.0);
  if n <> 0 then raise exception '% venue coordinates are outside Central Texas', n; end if;
end $$;

commit;

-- ===
-- db/migrations/143_westwood_warrior_bowl.sql
-- ===

-- 143_westwood_warrior_bowl.sql
--
-- Westwood: Warrior Bowl pin from Jeremy, 2026-08-16. Eighth split; pin
-- 30.4585172,-97.7979725 vs the campus address pin in the same URL (12400 Mellow
-- Meadow Dr) at 30.4566119,-97.7980504, ~210 m apart - the tightest of the eight,
-- and still a different parking lot.
--
-- Three rows move (2026-27 freshman Blue + Green, one 2025-26 row). Freshman
-- caveat applies as with Rouse, Vista Ridge and Cedar Ridge. 'Westwood High
-- School' (campus) stays unreferenced.

begin;

insert into venues (name, address, maps_url, latitude, longitude) values
  ('Westwood Warrior Bowl',
   '12400 Mellow Meadow Drive, Austin, TX 78750',
   'https://www.google.com/maps/place/Westwood+Warrior+Bowl/@30.4572381,-97.800711,794m/data=!3m1!1e3!4m15!1m8!3m7!1s0x865b32b867e9bfb5:0xd13fe8ad8cfb759e!2s12400+Mellow+Meadow+Dr,+Austin,+TX+78750!3b1!8m2!3d30.4566119!4d-97.7980504!16s%2Fg%2F11c3q4cb8c!3m5!1s0x865b33612b05c789:0x8420ac02db4a7637!8m2!3d30.4585172!4d-97.7979725!16s%2Fg%2F11j2x_qn_f',
   30.4585172, -97.7979725)
on conflict (name) do update
  set maps_url = excluded.maps_url,
      latitude = excluded.latitude,
      longitude = excluded.longitude,
      updated_at = now();

update games
   set venue_id = (select id from venues where name = 'Westwood Warrior Bowl')
 where location = 'Westwood HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Westwood Warrior Bowl';
  if n <> 3 then raise exception 'expected 3 games at Warrior Bowl (both seasons), got %', n; end if;

  select count(*) into n from games where location = 'Westwood HS' and venue_id is null;
  if n <> 0 then raise exception '% Westwood games lost their venue', n; end if;

  select count(*) into n from venues
   where maps_url like '%goo.gl%' or maps_url like '%entry=tt%' or maps_url like '%g_ep=%';
  if n <> 0 then raise exception '% venue URLs are shortened or carry session junk', n; end if;

  select count(*) into n from venues where (latitude is null) <> (longitude is null);
  if n <> 0 then raise exception '% venues have only half a coordinate', n; end if;

  select count(*) into n from venues
   where latitude is not null
     and (latitude not between 29.5 and 31.5 or longitude not between -98.5 and -97.0);
  if n <> 0 then raise exception '% venue coordinates are outside Central Texas', n; end if;
end $$;

commit;

-- ===
-- db/migrations/144_westlake_freshman_at_chaparral.sql
-- ===

-- 144_westlake_freshman_at_chaparral.sql
--
-- Jeremy 2026-08-16: the Westlake games are at Chaparral, same as varsity's.
-- Both rows are freshman (Blue 5:00, Green 6:30, Thu Oct 15) and were pointing
-- at the 'Westlake High School' campus venue - the district address, ~260 m from
-- the stadium and never verified by anyone.
--
-- No new venue: Chaparral Stadium already carries Jeremy's verified pin and
-- coordinates from migration 137. This is a repoint, which is the whole reason
-- venues are rows rather than per-game URLs - the correction is one statement
-- and the pin it lands on is already trusted.
--
-- Answers a question 137 explicitly left open. That migration kept Chaparral and
-- 'Westlake High School' as separate venues precisely BECAUSE the freshman rows
-- said 'Westlake HS' and might have meant a side field; Jeremy has now said they
-- do not. The campus venue stays in the table, unreferenced, for a future row
-- that genuinely means the campus.

begin;

update games
   set venue_id = (select id from venues where name = 'Chaparral Stadium')
 where location = 'Westlake HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where v.name = 'Chaparral Stadium';
  if n <> 3 then raise exception 'expected 3 games at Chaparral (1 varsity + 2 freshman), got %', n; end if;

  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.location = 'Westlake HS' and v.latitude is null;
  if n <> 0 then raise exception '% Westlake games still lack a verified pin', n; end if;
end $$;

commit;

-- ===
-- db/migrations/145_bowie_freshman_at_burger.sql
-- ===

-- 145_bowie_freshman_at_burger.sql
--
-- ⚠️ PROVISIONAL - the least certain venue call in this whole series. Rolled
-- back with 145_rollback.sql alone if it turns out wrong.
--
-- Jeremy 2026-08-16: "Bowie plays at Berger [Burger] from what I can tell" -
-- his own words carry the hedge. What is on each side:
--
--   FOR Burger: Bowie is an Austin ISD school and AISD runs shared district
--   stadiums; published Bowie sub-varsity results show freshman and JV home
--   games at Burger Stadium. Our own varsity row for the very next night is
--   already 'Burger Stadium'.
--
--   AGAINST: the school's schedule PDF - and therefore our rows - says
--   'Bowie HS' for the freshman games and 'Burger Stadium' for varsity, on
--   consecutive days. Whoever typed it used two different strings 24 hours
--   apart, which is at least weak evidence they meant two different places.
--   Sub-varsity on campus with varsity at the district stadium is the normal
--   AISD pattern.
--
-- Resolution: attach the Burger pin (verified, from Jeremy's first link) because
-- it is more likely right than a campus address nobody has checked - but LEAVE
-- THE DISPLAY LABEL as 'Bowie HS'. That is deliberate:
--   * changing the label to 'Burger Stadium' would put the site back in
--     disagreement with the Print View PDF, the exact defect fixed hours earlier
--     on 2026-08-16, on the strength of a hedge;
--   * the label is what the school published, and it is not wrong that the game
--     is "at Bowie" in the sense of "against Bowie, at their home site";
--   * if this turns out to be the campus after all, only the pin is wrong and it
--     is one statement to fix.
--
-- ⚠️ THE LABEL AND THE PIN THEREFORE DISAGREE for these two rows: the page reads
-- "Bowie HS" and links to Burger Stadium, ~8 miles apart. That is a real, visible
-- inconsistency and it is being carried ON PURPOSE pending confirmation. Jeremy
-- has been asked to confirm with Coach or Bowie athletics. Once confirmed:
--   * if Burger - set location = 'Burger Stadium' on these two rows AND patch the
--     freshman Aug. 27 row in the Print View PDF
--     (MavericksWebsite/scripts/patch-schedule-pdf-scrimmages.py), so all three
--     surfaces agree;
--   * if campus - run 145_rollback.sql and get a pin for the Bowie field.
-- Do not let this sit unresolved past Aug 27, when the game is played.

begin;

update games
   set venue_id = (select id from venues where name = 'Toney Burger Stadium')
 where location = 'Bowie HS';

do $$
declare n int;
begin
  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.location = 'Bowie HS' and v.name = 'Toney Burger Stadium';
  if n <> 2 then raise exception 'expected 2 Bowie freshman games at Burger, got %', n; end if;

  -- Every 2026-27 game now sits at a venue with a verified pin.
  select count(*) into n from games g left join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.location is not null
     and (v.id is null or v.latitude is null);
  if n <> 0 then raise exception '% 2026-27 games still lack a verified pin', n; end if;
end $$;

commit;

-- ===
-- db/migrations/146_bowie_label_burger_stadium.sql
-- ===

-- 146_bowie_label_burger_stadium.sql
--
-- Resolves the open question migration 145 carried. Jeremy checked satellite
-- imagery 2026-08-16: THERE IS NO STADIUM ON THE BOWIE CAMPUS. Bowie cannot host
-- a football game at its own address, which settles what 145 could only weigh -
-- Austin ISD sub-varsity plays at the district's shared stadiums, and for Bowie
-- that is Burger, the same venue as the varsity game the following night.
--
-- 145 attached the Burger pin but deliberately left the display label reading
-- 'Bowie HS', so the page said one place and its link went to another ~8 miles
-- away. That inconsistency was carried on purpose pending confirmation. It is
-- confirmed, so the label moves and the divergence closes.
--
-- All three surfaces now agree for this game:
--   games row      location 'Burger Stadium', venue Toney Burger Stadium
--   /events + ICS  derived from the same row, GEO 30.2305155;-97.8097468
--   Print View PDF freshman Aug. 27 SITE cell patched Bowie HS -> Burger Stadium
--                  (MavericksWebsite/scripts/patch-schedule-pdf.py, re-run from
--                  the school's original and re-uploaded)
-- Leaving any one of them behind is how this project got a site that disagreed
-- with its own printed schedule in the first place.
--
-- 'James Bowie High School' (campus, district address, no coordinates) stays in
-- the table unreferenced, like the other campus rows.

begin;

update games
   set location = 'Burger Stadium'
 where year = '2026-27' and location = 'Bowie HS';

do $$
declare n int;
begin
  select count(*) into n from games where year = '2026-27' and location = 'Bowie HS';
  if n <> 0 then raise exception '% rows still labelled Bowie HS', n; end if;

  select count(*) into n from games g join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.location = 'Burger Stadium'
     and v.name = 'Toney Burger Stadium';
  if n <> 3 then raise exception 'expected 3 Burger Stadium games (2 freshman + varsity), got %', n; end if;

  -- Label and pin must agree everywhere now: no 2026-27 game may sit at a venue
  -- whose name shares no word with its own display label, except the deliberate
  -- 'Maverick Stadium'/'McNeil' and KRAC-style shorthands already reviewed.
  select count(*) into n from games g left join venues v on v.id = g.venue_id
   where g.year = '2026-27' and g.location is not null
     and (v.id is null or v.latitude is null);
  if n <> 0 then raise exception '% 2026-27 games lack a verified pin', n; end if;
end $$;

commit;

-- ===
-- db/migrations/147_retire_stadiums_section.sql
-- ===

-- 147_retire_stadiums_section.sql
--
-- Retires the "Stadiums & Directions" section of /resources. Jeremy 2026-08-16,
-- and it is a consequence of the venue work rather than a preference: every game
-- on the site now carries its own verified pin (migrations 134-146), so a
-- hand-maintained list of three stadium links is strictly worse than the thing
-- next to the game itself. It also had the failure mode this whole day was about
-- - the list is only correct for the stadiums someone remembered to add.
--
-- Two of the three rows were demonstrably stale already:
--   'Dragon Stadium' pointed at 300 N Lake Creek Dr, the address migration 135
--   REJECTED in favour of 201 Deep Wood Dr once Jeremy sent the real pin.
--   'House Park' is not on the 2026-27 schedule at all; it is a 2025-26 venue.
-- Only KRAC was still right, and KRAC now has a verified pin on every row that
-- plays there.
--
-- DEACTIVATED, NOT DELETED - same treatment as migrations 111 and 113. If the
-- section ever comes back the rows are recoverable, and `active = false` is what
-- getResourceLinks already filters on, so this needs no code to take effect.
--
-- ⚠️ The `resource_links.section` ENUM keeps its 'stadiums' value. Dropping an
-- enum value is a rewrite of the column's type for three dead rows, and Postgres
-- cannot drop one in-place anyway. The page-side guard is that any link whose
-- section is not in SECTION_ORDER now falls into "Other" rather than vanishing -
-- so if someone adds a stadiums row later it appears somewhere visible instead
-- of being silently dropped.
--
-- The clear bag policy is NOT a row here and is unaffected: it lives in
-- lib/constants.ts (CLEAR_BAG_POLICY_URL), shared with both games pages, and
-- moves in the same commit from a footnote under Stadiums to an entry under
-- Resources.

begin;

update resource_links
   set active = false
 where section = 'stadiums' and active = true;

do $$
declare n int;
begin
  select count(*) into n from resource_links where section = 'stadiums' and active = true;
  if n <> 0 then raise exception '% stadiums links still active', n; end if;

  select count(*) into n from resource_links where section = 'stadiums';
  if n <> 3 then raise exception 'expected 3 archived stadiums rows, got %', n; end if;

  -- Nothing else may have been touched.
  select count(*) into n from resource_links where section <> 'stadiums' and active = true;
  if n <> 12 then raise exception 'expected 12 active non-stadium links, got %', n; end if;
end $$;

commit;

-- /resources is force-dynamic: live with no deploy (the code change ships with it).

-- ===
-- db/migrations/148_single_freshman_team.sql
-- ===

-- 148_single_freshman_team.sql
--
-- McNeil is fielding ONE freshman team in 2026-27, not two. Coach told Jeremy
-- 2026-08-17. This was always the anticipated case -- `freshman_has_blue` exists
-- for exactly this -- so it is a flag flip plus retiring the Blue roster row,
-- not a structural change.
--
-- What the flag does on its own, no code change required:
--   * /roster/freshman/blue and /schedule/games/freshman/blue both notFound()
--   * `showDesignation` goes false, so every user-visible label drops the colour
--     and reads plain "Freshmen" -- which is precisely Jeremy's "just Green or
--     no color". The URL keeps /green; only the wording changes.
--   * Both Blue entries leave the header and mobile nav (buildScheduleLinks /
--     buildRosterLinks).
--   * The practice page title stops reading "Freshmen Green & Blue".
--   * getGamesAsEvents drops every freshman Blue row, so /events, the month view
--     and the ICS feed lose them too.
--
-- ── ⚠️ THE 12 FRESHMAN BLUE GAME ROWS ARE LEFT IN PLACE, DELIBERATELY ──
-- The flag already makes them unreachable on every surface, so deleting them
-- buys nothing and costs the one thing still unresolved: Blue and Green are the
-- SAME 12 fixtures -- identical opponent, venue and home/away on every date --
-- differing only in kickoff time. The two scrimmages (Aug 13, Aug 20) are 5:30
-- for both, but all 10 regular-season games are Blue 5:00 p.m. vs Green 6:30 p.m.
--
-- Nobody has yet said which of those two slots the single team plays. Green
-- survives, so the site currently publishes 6:30. If the answer turns out to be
-- 5:00, the Blue rows ARE the record of that timing and the fix is one UPDATE
-- against them. Throwing them away would mean re-deriving a time we already
-- have on file.
--
-- ⚠️ DO NOT let this sit unanswered past Thu Aug 27, the first affected game.
-- The Aug 20 Eastview scrimmage is unaffected (5:30 either way).
--
-- Rollback: 148_rollback.sql

begin;

do $$
declare n int;
begin
  select count(*) into n from site_settings where freshman_has_blue;
  if n <> 1 then
    raise exception 'Expected freshman_has_blue = true before this migration, found % row(s) set', n;
  end if;

  select count(*) into n
    from rosters where year = '2026-27' and team_level = 'freshman' and active;
  if n <> 2 then
    raise exception 'Expected 2 active 2026-27 freshman rosters (Green + Blue), found %', n;
  end if;
end $$;

update site_settings set freshman_has_blue = false;

-- Deactivated, not deleted -- the project's standing pattern (111 Rudy's,
-- 113 Program Ad, 147 Stadiums). The row carries its id and created_at, and
-- the roster pages already filter on active.
update rosters
   set active = false
 where year = '2026-27'
   and team_level = 'freshman'
   and team_designation = 'Blue';

do $$
declare n int;
begin
  select count(*) into n
    from rosters where year = '2026-27' and team_level = 'freshman' and active;
  if n <> 1 then
    raise exception 'Expected exactly 1 active 2026-27 freshman roster after the flip, found %', n;
  end if;

  select count(*) into n from site_settings where freshman_has_blue;
  if n <> 0 then
    raise exception 'freshman_has_blue is still set on % row(s)', n;
  end if;
end $$;

commit;

-- ===
-- db/migrations/149_event_signup_label.sql
-- ===

-- 149_event_signup_label.sql
--
-- Picture Day photo ordering. Coach sent Jeremy the photographer's ImageQuix
-- link 2026-08-19 and asked for it on the Picture Day event, two days before
-- pictures are taken (Fri Aug 21).
--
-- WHY A NEW COLUMN AND NOT JUST signup_url. The detail page's CTA label is the
-- literal string "Sign Up →". That is correct for all three events currently
-- using signup_url (youth camp, senior program ad, pool party) — every one is a
-- Google Form you sign up on. This link is a STORE: it resolves to
-- shop.imagequix.com and sells photos. "Sign Up" on a checkout is a lie about
-- what the button does, and relabelling the shared button would break the three
-- rows that mean it literally. So the label becomes per-row, defaulting to the
-- old string when NULL — the three existing rows are untouched and keep
-- rendering exactly as they do today.
--
-- Rejected: putting the URL in `description`. The /events list card and the ICS
-- feed render description as PLAIN TEXT (only the detail page runs it through
-- ReactMarkdown), so a markdown link would render as literal "[Order
-- photos](https://…)" on the list and in every subscribed calendar, and a bare
-- URL would eat the call times out of the card's line-clamp-3.
--
-- Rejected: reusing photos_url. Its button reads "View Photos" and sits next to
-- the free club Google Photos albums (migration 114) in the past-events list.
-- Conflating a paid vendor storefront with a club album is exactly the kind of
-- thing a parent would click expecting free.
--
-- LABEL IS "Order Photos", not "Pre-Order Photos" (Jeremy 2026-08-19). It reads
-- correctly both before Friday, when the store is a prepay, and after, when the
-- same gallery holds the actual proofs. "Pre-Order" would need someone to
-- remember to change it on Aug 21 and nobody would.
--
-- ⚠️ THE URL PUBLISHED HERE IS THE `vando.imagequix.com` FORM COACH SENT, NOT
-- the `shop.imagequix.com/g1001432099` it redirects to. The `g…` id is an
-- ImageQuix-internal gallery id; the vando code + keyword is the link the
-- photographer hands out. Same reasoning as the Venmo profile-link fallback:
-- publish the vendor's public entry point, not the internal id you observed it
-- resolving to today.
--
-- VERIFIED LIVE 2026-08-19 before publishing, by rendering the URL in a real
-- browser (the page is a JS SPA — curl returns only an empty shell, and a
-- headless-Chromium user agent gets served "Page Not Found", so neither proves
-- anything). Rendered with a normal desktop UA it 302s to
-- shop.imagequix.com/g1001432099 and the page title is exactly
-- "McNeil HS (RRISD) F26 Football". A link to the WRONG school's gallery is
-- worse than no link, and nothing on this site can detect that later.
--
-- ⚠️ This link rots silently, same as photos_url. If the photographer closes
-- the gallery, the site shows a dead checkout with no signal. Both columns are
-- nullable and every render site hides its affordance when null, so pulling it
-- down is a one-line UPDATE with no deploy.
--
-- The description also gains one sentence saying the charge is the
-- photographer's (Jeremy 2026-08-19) — the club takes money on this site for
-- memberships and sponsorships, so an unattributed "Order Photos" button on a
-- club page reads as a club charge.

begin;

alter table events
  add column if not exists signup_label text;

comment on column events.signup_label is
  'CTA label for signup_url. NULL means "Sign Up" — the default for the Google '
  'Form signups this column was added around. Set it when the destination is '
  'not a signup (e.g. a photo vendor''s store), so the button says what it does. '
  'Meaningless without signup_url; render sites read it as (signup_label ?? "Sign Up").';

-- Guard: the three existing signup_url rows must stay on the default label.
-- If a later migration sets one, this assertion is the place to find out.
do $$
declare n int;
begin
  select count(*) into n from events
   where signup_url is not null and signup_label is not null;
  if n <> 0 then
    raise exception 'expected 0 pre-existing labelled signups, found %', n;
  end if;
end $$;

update events
set signup_url   = 'https://vando.imagequix.com/P9M6G96?keyword=McNeilHSFBF26',
    signup_label = 'Order Photos',
    description  = description ||
      ' Photos are ordered from the school photographer''s online gallery; the club does not process the charge.'
where slug = 'picture-day-2026'
  and signup_url is null
  and description = 'Team and individual photos for all three levels. Upperclassmen (Soph/Jr/Sr): 7:00 a.m. arrival, pictures complete by 8:00 a.m., film during Period 2. Freshmen: 8:00 a.m. arrival, pictures complete by 9:15 a.m., film after pictures if time permits.';

-- Match on the exact prior description so a re-run cannot append the sentence
-- twice and an edited description aborts loudly rather than being clobbered.
do $$
declare n int;
begin
  select count(*) into n from events
   where slug = 'picture-day-2026'
     and status = 'published'
     and signup_url = 'https://vando.imagequix.com/P9M6G96?keyword=McNeilHSFBF26'
     and signup_label = 'Order Photos'
     and description like '%school photographer''s online gallery%'
     and description not like '%school photographer''s online gallery%school photographer''s online gallery%';
  if n <> 1 then
    raise exception 'picture-day-2026 ordering link not applied as expected (matched % rows)', n;
  end if;
end $$;

commit;

-- /events and /events/<slug> are force-dynamic / request-time, so the button is
-- live with no deploy ONCE THE CODE THAT READS signup_label IS DEPLOYED. Before
-- that deploy the button renders the old "Sign Up →" string against a store URL,
-- which is the wrong label on a checkout — apply this migration and ship the
-- code together.
--
-- ⚠️ /events.ics is CDN-cached for an hour. Irrelevant here (the feed carries no
-- signup field) but noted so nobody goes looking for the link in a calendar.

-- ===
-- db/migrations/150_practice_picture_day_ordering_pointer.sql
-- ===

-- 150_practice_picture_day_ordering_pointer.sql
--
-- Points the Friday Aug 21 picture-day block on all three practice pages at the
-- Picture Day event, where migration 149 put the photographer's ordering button.
-- Jeremy 2026-08-19, alongside 149.
--
-- ⚠️ THE POINTER IS A RELATIVE LINK TO /events/picture-day-2026, NOT THE VENDOR
-- URL. That is the whole design. Migration 133 deliberately kept picture day on
-- the practice pages as well as /events, so a family reading Friday's practice
-- block does not have to know to also check the calendar — which means the
-- ordering link has FOUR candidate homes (three practice bodies + the event).
-- Pasting the vando URL into all four is precisely the duplicated-fact drift
-- this project keeps paying for: when the photographer reissues the gallery,
-- three stale checkouts stay live and nothing signals it. One copy of the URL,
-- in events.signup_url, and everything else links to the page that holds it.
--
-- The bodies render through ReactMarkdown with remark-gfm and styled anchors
-- (app/schedule/practice/[level]/page.tsx), so a markdown link works here — it
-- does NOT on the /events list card or in the ICS feed, which is why 149 needed
-- a real column instead. Different render paths, different affordances.
--
-- Each UPDATE matches the ENTIRE Friday block, header and all, and asserts the
-- body actually changed. Anchoring on "Film during Period 2" alone would be one
-- ambiguous string away from rewriting the Wednesday Period 2 line instead, and
-- the varsity/jv tail ("Film during Period 2") differs from the freshman one
-- ("Film after pictures, time permitting") — so this cannot be one statement.
-- Verified before writing: every anchor below occurs exactly once per body.
--
-- Idempotent: the WHERE clause requires the pointer to be ABSENT, so a re-run
-- is a no-op rather than a second bullet.

begin;

-- Varsity and JV practice together and share the upperclassmen 7:00/8:00 block.
update practice_schedules
set body = replace(
  body,
  E'### Friday, Aug 21 — picture day\n- **7:00 a.m.** — Arrival\n- **8:00 a.m.** — Pictures complete\n- Film during Period 2',
  E'### Friday, Aug 21 — picture day\n- **7:00 a.m.** — Arrival\n- **8:00 a.m.** — Pictures complete\n- Film during Period 2\n- Photo ordering: see the [Picture Day event](/events/picture-day-2026).'
)
where year = '2026-27'
  and team_level in ('varsity', 'jv')
  and body like '%### Friday, Aug 21 — picture day%'
  and body not like '%/events/picture-day-2026%';

-- One freshman team as of migration 148; 8:00/9:15 block, film only if time.
update practice_schedules
set body = replace(
  body,
  E'### Friday, Aug 21 — picture day\n- **8:00 a.m.** — Arrival\n- **9:15 a.m.** — Pictures complete\n- Film after pictures, time permitting',
  E'### Friday, Aug 21 — picture day\n- **8:00 a.m.** — Arrival\n- **9:15 a.m.** — Pictures complete\n- Film after pictures, time permitting\n- Photo ordering: see the [Picture Day event](/events/picture-day-2026).'
)
where year = '2026-27'
  and team_level = 'freshman'
  and body like '%### Friday, Aug 21 — picture day%'
  and body not like '%/events/picture-day-2026%';

-- All three bodies must now carry exactly one pointer. A silently-unmatched
-- replace() returns the body unchanged and reports success, which is how a
-- "done" migration leaves a page with no link on it.
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and active
     and (length(body) - length(replace(body, '/events/picture-day-2026', '')))
         / length('/events/picture-day-2026') = 1;
  if n <> 3 then
    raise exception 'expected 3 practice bodies with one ordering pointer, found %', n;
  end if;
end $$;

-- The pointer must sit inside the Friday block, not wherever replace() felt
-- like putting it: it has to fall between the Friday header and Saturday's.
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27'
     and active
     and position('/events/picture-day-2026' in body) > position(E'### Friday, Aug 21' in body)
     and position('/events/picture-day-2026' in body) < position(E'### Saturday, Aug 22' in body);
  if n <> 3 then
    raise exception 'ordering pointer landed outside the Friday block in % of 3 bodies', 3 - n;
  end if;
end $$;

commit;

-- /schedule/practice/* reads at request time: live with no deploy. Unlike 149,
-- this migration needs no code change at all.

-- ===
-- db/migrations/151_senior_night_to_oct_9.sql
-- ===

-- 151_senior_night_to_oct_9.sql
--
-- Senior Night moves off the Sept 4 home opener (Lake Belton) and onto the
-- Oct 9 home game vs Stony Point. Jeremy 2026-08-19.
--
-- It lands three weeks before Homecoming (Oct 23, migration 057) rather than on
-- top of it, which is the point: those are the only two occasion markers the
-- season carries and both render in the game title, so sharing a night would
-- have put "(Homecoming) (Senior Night)" on one row and given the seniors the
-- smaller half of the evening.
--
-- `notes` is doing double duty in this table — it holds the literal string
-- 'Scrimmage', which `gameTitle()` splices into the MIDDLE of the title, and
-- occasion markers like Homecoming / Senior Night, which it appends in parens.
-- This migration only ever touches the occasion kind. Do not let a 'Scrimmage'
-- row acquire an occasion marker: the title builder handles one or the other,
-- not both, and the Aug 13/Aug 20 scrimmages are the rows at risk.
--
-- DB-ONLY, NO DEPLOY. /events, /schedule/games/* and the month view all read at
-- request time, so the title changes as soon as this commits. ⚠️ /events.ics is
-- CDN-cached for an hour — verify the feed with a cache-buster (`?cb=1`) or you
-- will read a stale title and think this failed.
--
-- Oct 9 is NOT the last home game (Oct 23 vs Round Rock is). That is Jeremy's
-- call, not a mistake to be "fixed" by a later migration.

begin;

-- Guard the starting state. If Senior Night has already been moved, or sits on
-- more than one row, stop rather than guess which one is authoritative.
do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and notes = 'Senior Night';
  if n <> 1 then
    raise exception 'expected exactly 1 Senior Night row in 2026-27, found %', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and (game_date at time zone 'America/Chicago')::date = '2026-09-04'
     and notes = 'Senior Night';
  if n <> 1 then
    raise exception 'Senior Night is not on the 2026-09-04 varsity game (matched % rows)', n;
  end if;
end $$;

-- The destination must exist, be the only game that day, and be unmarked -
-- overwriting an existing note here would silently drop it.
do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27'
     and (game_date at time zone 'America/Chicago')::date = '2026-10-09';
  if n <> 1 then
    raise exception 'expected exactly 1 game on 2026-10-09, found %', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and (game_date at time zone 'America/Chicago')::date = '2026-10-09'
     and opponent = 'Stony Point High School'
     and home_or_away = 'home'
     and notes is null;
  if n <> 1 then
    raise exception 'the 2026-10-09 varsity Stony Point home game is not present and unmarked (matched % rows)', n;
  end if;
end $$;

update games
set notes = null
where year = '2026-27' and team_level = 'varsity'
  and (game_date at time zone 'America/Chicago')::date = '2026-09-04'
  and notes = 'Senior Night';

update games
set notes = 'Senior Night'
where year = '2026-27' and team_level = 'varsity'
  and (game_date at time zone 'America/Chicago')::date = '2026-10-09'
  and opponent = 'Stony Point High School'
  and notes is null;

-- End state: one Senior Night in the season, on Oct 9, and the Sept 4 game
-- carries no marker at all. Homecoming must be untouched.
do $$
declare n int;
begin
  select count(*) into n from games
   where year = '2026-27' and notes = 'Senior Night'
     and (game_date at time zone 'America/Chicago')::date = '2026-10-09';
  if n <> 1 then
    raise exception 'Senior Night did not land on 2026-10-09 (matched % rows)', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and notes = 'Senior Night';
  if n <> 1 then
    raise exception 'expected exactly 1 Senior Night row after the move, found %', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and team_level = 'varsity'
     and (game_date at time zone 'America/Chicago')::date = '2026-09-04'
     and notes is null;
  if n <> 1 then
    raise exception 'the Sept 4 game did not come back clean (matched % rows)', n;
  end if;

  select count(*) into n from games
   where year = '2026-27' and notes = 'Homecoming'
     and (game_date at time zone 'America/Chicago')::date = '2026-10-23';
  if n <> 1 then
    raise exception 'Homecoming was disturbed (matched % rows on 2026-10-23)', n;
  end if;
end $$;

commit;

-- ===
-- db/migrations/152_scrimmage_no_meals_warning.sql
-- ===

-- 152_scrimmage_no_meals_warning.sql
--
-- Coach's Thursday reminder (2026-08-19, the night before) says plainly:
-- "Athletes should bring extra food or a snack. We do not provide meals for
-- scrimmages." Nothing on the site said so. Jeremy asked for it on the page.
--
-- WHY THIS ONE LINE AND NOT THE REST OF THE MESSAGE. Everything else coach sent
-- either already matched or was a rounding difference:
--   * "practice during 2nd period" vs the page's "Period 6" is NOT a conflict.
--     McNeil runs an every-other-day block: periods 1-4 one day, 5-8 the next,
--     and varsity athletics is daily in the same slot - called 2nd on odd days
--     and 6th on even. Thursday Aug 20 is a 5-8 day, so Period 6 is correct.
--     ⚠️ Do not "fix" a Period 2/Period 6 mismatch against a coach message
--     again; check which block day it is first.
--   * on-field times 5:00 and 6:30 in the message vs 4:55 and 6:25 here. The
--     page follows the weekly schedule's arrival-plus-25 convention throughout
--     (7:00→7:25, 9:00→9:20, 8:00→8:25, 4:30→4:55, 6:00→6:25); the reminder
--     rounds. Arrival times - the ones that actually govern when a parent
--     drops off - agree exactly, so the page keeps the precise numbers.
--
-- Placed in the Thursday scrimmage block rather than as a season-wide note.
-- Aug 20 is the LAST scrimmage (Aug 13 was the other; Aug 27 starts games), so
-- a general "scrimmages have no meals" rule has exactly one occurrence left to
-- apply to, and meals ARE provided for games - which is the fact a season-wide
-- placement would blur.
--
-- Anchored to each body's own scrimmage line and asserted per level: varsity
-- carries the 7:00 upperclassmen block, jv and freshman the 5:30 Freshman & JV
-- block. Verified before writing that each anchor occurs exactly once in its
-- body and that no body already mentions a snack.
--
-- DB-ONLY, NO DEPLOY. /schedule/practice/* reads at request time.

begin;

-- Upperclassmen: after the 7:00 p.m. scrimmage line.
update practice_schedules
set body = replace(
  body,
  E'**7:00 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium',
  E'**7:00 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium\n- **Bring extra food or a snack.** Meals are not provided for scrimmages.'
)
where year = '2026-27'
  and team_level = 'varsity'
  and body like '%**7:00 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium%'
  and body not like '%Meals are not provided for scrimmages%';

-- Freshman & JV: after the 5:30 p.m. scrimmage line, in both bodies.
update practice_schedules
set body = replace(
  body,
  E'**5:30 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium',
  E'**5:30 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium\n- **Bring extra food or a snack.** Meals are not provided for scrimmages.'
)
where year = '2026-27'
  and team_level in ('jv', 'freshman')
  and body like '%**5:30 p.m.** — Scrimmage begins at McNeil High School Mavericks Stadium%'
  and body not like '%Meals are not provided for scrimmages%';

-- All three bodies must carry exactly one warning. A replace() that matched
-- nothing returns the body unchanged and reports success - which is how a
-- "done" migration leaves the page without the line it was written to add.
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and active
     and (length(body) - length(replace(body, 'Meals are not provided for scrimmages', '')))
         / length('Meals are not provided for scrimmages') = 1;
  if n <> 3 then
    raise exception 'expected 3 bodies with exactly one no-meals warning, found %', n;
  end if;
end $$;

-- It has to sit inside the Thursday block, not wherever replace() put it:
-- after the Thursday header and before Friday's.
do $$
declare n int;
begin
  select count(*) into n from practice_schedules
   where year = '2026-27' and active
     and position('Meals are not provided' in body) > position(E'### Thursday, Aug 20' in body)
     and position('Meals are not provided' in body) < position(E'### Friday, Aug 21' in body);
  if n <> 3 then
    raise exception 'warning landed outside the Thursday block in % of 3 bodies', 3 - n;
  end if;
end $$;

commit;
