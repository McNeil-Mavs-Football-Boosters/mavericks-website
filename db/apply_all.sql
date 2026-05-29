
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
