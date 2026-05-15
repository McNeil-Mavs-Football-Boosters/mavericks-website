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
