# Database Schema — Phase 1

Postgres schema for the new mcneilmavericks.org, hosted on Supabase. Written 2026-05-14.

**Reads with:** `content_map.md` (what each page needs), `admin_scope.md` (what each admin role can do), `spec_review.md` (resolution log for open questions).

**Stack note:** Supabase = Postgres + PostgREST API + Row-Level Security (RLS) + Auth + Storage. Every table gets RLS policies. Public read access for content tables; authenticated-only for everything else. Admin role checks via JWT claims.

---

## Conventions

- Primary keys: `id uuid PRIMARY KEY DEFAULT gen_random_uuid()` on every table
- Timestamps: `created_at`, `updated_at` (auto-updated via trigger) on every table
- Audit: `last_edited_by uuid REFERENCES auth.users(id)` on every editable table
- Soft deletes: `active boolean DEFAULT true` rather than hard DELETE for collections; admin UI shows active by default with a "show archived" toggle
- Money: always `integer` cents (e.g., `price_cents int NOT NULL`), never floats
- School-year fields: `year text NOT NULL` storing format `"2026-27"`, not `"2026"`
- File uploads: stored in Supabase Storage, table stores the public URL as `text`
- Enums: Postgres `CREATE TYPE ... AS ENUM (...)` rather than text + check constraint
- Indexes: every FK gets an index; every column used in a WHERE on the public site gets an index

---

## Auth & roles

Supabase Auth handles `auth.users` (built in). We add a small `user_roles` table for app-level role assignment.

```sql
CREATE TYPE user_role AS ENUM ('super_admin', 'content_admin', 'readonly_admin');

CREATE TABLE user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
```

A user can have multiple roles (rare but possible — e.g., super_admin also having content_admin for testing).

**Helper function for RLS:**

```sql
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
```

---

## Content tables

### news_posts

```sql
CREATE TYPE post_status AS ENUM ('draft', 'published');

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
```

### events

```sql
CREATE TYPE event_status AS ENUM ('draft', 'published', 'cancelled');

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
```

### membership_tiers

```sql
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
```

### sponsorship_tiers

```sql
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
```

### sponsors

```sql
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
```

### board_members

```sql
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
```

### committees

```sql
CREATE TYPE committee_cadence AS ENUM ('ongoing', 'seasonal', 'one_time');

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
```

### volunteer_opportunities

```sql
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
```

### documents

```sql
CREATE TYPE document_type AS ENUM ('governance', 'financial', 'minutes', 'sponsor_flyer', 'other');

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
```

---

## Transactional tables

### payments

Records every Stripe transaction (and manual cash/check entries). Source of truth for "who has paid what."

```sql
CREATE TYPE payment_method_type AS ENUM ('stripe', 'cash', 'check', 'zero_dollar', 'other');
CREATE TYPE payment_purpose AS ENUM ('membership', 'donation', 'sponsorship');
CREATE TYPE payment_status AS ENUM ('pending', 'succeeded', 'failed', 'canceled', 'refunded');

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
```

**payment_status note:** `canceled` is included to handle Stripe's `checkout.session.expired` and explicit cancellation events. The webhook handler maps Stripe's terminal states to this enum.

**Webhook idempotency (N1):** Stripe retries webhook deliveries; `checkout.session.completed` can fire more than once for the same session. The build plan's webhook handler MUST upsert defensively, e.g.:

```sql
INSERT INTO payments (stripe_session_id, ...) VALUES ($1, ...)
ON CONFLICT (stripe_session_id) DO UPDATE
SET status = EXCLUDED.status, updated_at = now()
WHERE payments.status != 'succeeded';  -- don't re-overwrite a terminal state
```

The `UNIQUE` constraint on `stripe_session_id` is the database-level safety net; the application code must handle the conflict gracefully.

**`recorded_by` vs `last_edited_by` semantics (N2):**
- `recorded_by` = who first created the row. NULL for self-service Stripe payments (the customer is anon and not a `auth.users` record). Populated for admin-entered manual cash/check rows.
- `last_edited_by` = who last edited any field on the row. NULL until an admin edits something (e.g., adds a note). Stripe-originated rows that no one has touched stay NULL.

### memberships

Replaces the Google Form. Every membership signup writes a row. Linked to `payments` once paid.

```sql
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

CREATE TRIGGER validate_membership_paid_state_trigger
  BEFORE INSERT OR UPDATE ON memberships
  FOR EACH ROW
  EXECUTE FUNCTION validate_membership_paid_state();
```

**Why `tier_id` is `ON DELETE RESTRICT`:** we don't want to lose membership records when a tier is renamed or archived. Soft-archive tiers via `active = false` instead.

---

## Settings tables

### site_settings

Single-row table. Easier than a key-value store for typed values.

```sql
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
```

Singleton enforced via `CHECK (id = 1)` + a seed row inserted at schema creation.

**Quick action card enum** (application-level enforcement since Postgres `CHECK IN (...)` is rigid):
- `join` → "Become a Member" → /join
- `sponsor` → "Become a Sponsor" → /sponsor
- `donate` → "Make a Donation" → /join#donate
- `volunteer` → "Volunteer" → /get-involved
- `newsletter` → "Subscribe" → /contact#newsletter

Icons and labels for each are defined in code, not the DB.

---

## Triggers — updated_at maintenance

```sql
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
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
```

---

## Row-Level Security (RLS)

**Default:** RLS enabled on every table. No policies = no access (deny by default). Then add policies explicitly.

### Public content tables — full policy set

Every table here gets the same pattern: anon SELECT for "visible" rows, content_admin gets full CRUD.

```sql
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
```

### Private tables — memberships and payments

`memberships` rows are never directly readable by anonymous visitors. The `/members` page reads from a Postgres view that exposes only display-safe columns.

**The public_members view (S2 fix — column-level safety):**

```sql
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
```

**memberships table RLS — no anon access at all:**

```sql
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
```

**Why no anon INSERT:** money-adjacent writes need server-side validation. Letting anon write directly to `memberships` would let an attacker POST `{ paid: true, list_publicly: true, tier_id: <expensive_tier> }` and bypass Stripe entirely. The `/api/memberships/create` route runs server-side with the service role key, validates input, forces `paid = false`, and either redirects to Stripe Checkout (paid tiers) or completes the row (Free Fan Base $0 tier). The Stripe webhook (`/api/stripe/webhook`) flips `paid = true` on `checkout.session.completed`. The `validate_membership_paid_state` trigger is a belt-and-suspenders backup.

**Payments RLS:**

```sql
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
```

**Note on Stripe webhook:** the webhook handler runs server-side as the Supabase service role, which bypasses RLS entirely. Standard pattern — webhook code in a server-side API route with the service key, never in the browser. Same for the `/api/memberships/create` endpoint.

### user_roles RLS

```sql
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
```

---

## Seed data (run after schema creation, before first deploy)

```sql
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

-- site_settings already inserted via INSERT...ON CONFLICT in the table definition above
```

---

## Migration plan — existing data

35 signups exist in Jeremy's 2026-27 Google Form. 7 are paid, 8 are "email-sent" (invoice issued, payment never came in), 20 have no payment status (likely abandoned or never invoiced).

**Approach:**

1. Export the Google Form responses to CSV
2. Write a one-time migration script that maps form columns → `memberships` columns
3. For each row:
   - Look up the tier by name (e.g., "Game Day! - $20" → match against `membership_tiers.name`)
   - Set `paid = true` only if `Payable Status = 'paid'`
   - For the 7 confirmed paid rows, create a `payments` row with `method = 'other'` and `notes = 'Pre-cutover payment via Google Form / SE Payments / legacy invoice — migrated YYYY-MM-DD'`. **Do NOT use `method = 'stripe'`** — those payments are not in our new Stripe account and would mislead Treasurer reconciliation (no matching Stripe dashboard entry).
   - Leave the other 28 rows with `payment_id = null` and `paid = false`
4. After import, send re-invoicing emails to the 8 "email-sent" rows pointing them to the new Stripe-backed `/join` page
5. The 20 with no payment status: mark as `paid = false`, no payment row, archive after 60 days if still unpaid (set `active = false` per the soft-delete semantics)

This script is the one piece of throwaway code in Phase 1. It runs once. Don't build admin UI for it.

---

## Open questions (don't block implementation)

1. **Should `payments` track Stripe fees?** Current schema stores `amount_cents` as gross. Net = gross - Stripe fee. Treasurer might want to see net for reconciliation. Resolution: add `stripe_fee_cents int` later if Chevon asks; not blocking.
2. **Should there be a `donations` separate from `memberships`?** Right now a $50 donation that's not tied to membership goes into `payments` with `purpose = 'donation'` and no membership row. Works fine. Could add a `donations` table if we want richer donor profiles, but YAGNI for Phase 1.
3. **Should `news_posts` support categories/tags?** Stony Point doesn't. Skipping for Phase 1.

---

## Design notes — placeholder seed content

These are flagged because they'll appear on the live site at launch unless someone edits them. Board can change in admin UI without code change, but worth pointing out:

1. **Sponsorship tier perks (Q12)** — the specific perks in the seed data ("6x 30-sec audio commercials per game", "Game program: Cover ad", "Streaming banner all games") are lifted from Stony Point's actual sponsorship flyer. The McNeil booster club may or may not actually offer streaming, a program, or PA announcements. Kendra (VP Fundraising) needs to edit these to match what McNeil can actually deliver before Sponsor outreach begins. Placeholders are clearly identifiable in the seed.
2. **Membership tier perks (Q13)** — "Newsletter access" and "Community updates" appear as Free Fan Base perks. No newsletter feature exists in Phase 1 (just a contact form). These should either be removed by the board or fulfilled via a real comms channel (SportsYou? GroupMe? Email blasts from `boosters@`?). Placeholder copy, board to refine.
3. **/members page language vs $0 supporters (Q11)** — The public_members view shows everyone with `paid = true AND list_publicly = true`. Free Fan Base ($0) members are `paid = true` because the trigger lets them be. They appear on /members alongside dues-paying members. Two paths: soften the page heading from "dues-paid members" to "thank you to our supporters" (recommended — these 7 people of the current 35 are real supporters), or filter the view to add `AND mt.price_cents > 0`. Default is the inclusive option; board can decide.

---

## Storage buckets (Supabase Storage — I10)

The schema references public URLs in five places but doesn't define the buckets. Storage buckets are configured separately from SQL schema in Supabase, typically via the dashboard or CLI. Phase 1 needs:

| Bucket name | Public? | Purpose | Max file size | Allowed MIME |
|---|---|---|---|---|
| `news-images` | Yes | `news_posts.featured_image_url`, inline images in news bodies | 5 MB | image/png, image/jpeg, image/webp |
| `event-images` | Yes | `events.cover_image_url` | 5 MB | image/png, image/jpeg, image/webp |
| `sponsor-logos` | Yes | `sponsors.logo_url` | 2 MB | image/png, image/jpeg, image/svg+xml, image/webp |
| `board-photos` | Yes | `board_members.photo_url` | 5 MB | image/png, image/jpeg, image/webp |
| `site-images` | Yes | `site_settings.hero_image_url` and other one-off marketing images | 10 MB (hero is bigger) | image/png, image/jpeg, image/webp |
| `documents` | Yes (with caveat — see below) | `documents.file_url` (bylaws, IRS letter, minutes PDFs) | 25 MB | application/pdf |

**Why all public:** these URLs are referenced on the public site. Marking buckets public lets the Next.js pages load them without signed URLs (faster, simpler, no auth dance for image renders).

**Caveat on `documents`:** Phase 1 has no private-document concept. All documents are visible to anyone with the file URL; visibility is gated only by `documents.active` at the DB layer (soft-archive removes them from the public listing, but the file URL itself remains live if someone has it bookmarked). If Phase 2 introduces confidential financial documents, restore a `public` column on `documents` and add a separate private bucket with signed-URL access.

**Storage RLS-equivalent (called "policies" in Supabase Storage):**

```sql
-- All buckets above: anyone can read, only authenticated content_admins can write/delete
-- Apply this template per bucket via Supabase dashboard or storage.objects table policies

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
```

**Application-level upload constraints** (enforced in API routes, not DB):
- Client-side image resize to max 2000px on long edge before upload
- Validate MIME type against the bucket's allowed list before upload
- Reject files exceeding max size
- Generate descriptive filenames: `{table}/{record_id}/{timestamp}_{slugified_original_name}.{ext}`

---

## What's not in this schema

For the avoidance of doubt:

- **Audit log table** — Phase 1 uses `last_edited_by` + `updated_at` columns on each table. Full audit history (who changed what, with diffs) is Phase 2.
- **Store / merch / orders** — Phase 3
- **Photo gallery** — Phase 3
- **Newsletter subscribers** — captured via contact form to admin's email for Phase 1; no `subscribers` table until we have a real newsletter platform integration
- **Per-collection permissions** — content_admin can edit everything in scope; no fine-grained "this user can edit news but not events" until requested
- **Versioning / drafts beyond status flag** — news/events have a draft/published flag; no full revision history
- **Application-level Stripe amount calculation** — at `/join` checkout, the Stripe Checkout session `amount_cents` is computed as `membership_tier.price_cents + memberships.additional_donation_cents`. This is application logic in `/api/memberships/create`, not a DB column. Calling out because the schema captures the donation amount but doesn't encode the sum.
- **Payment purpose alignment enforcement** — `memberships.payment_id` and `sponsors.payment_id` don't enforce that the linked payment's `purpose` matches the linking table (e.g., a membership row could in theory link to a payment with `purpose = 'sponsorship'`). This is left as application-layer responsibility — the API routes that create those links must validate. We are explicitly trusting app code here rather than adding another validation trigger; the probability of an admin-written bug doing this is low, and trigger complexity isn't free.
- **Implementation order** — moved out of this doc. Schema is the contract; sequencing belongs in the Phase 1 build plan.
- **Document privacy toggle** — `documents.public` column dropped for Phase 1 (per CC review D1). All Phase 1 documents are public. Restore the column in Phase 2 when/if a private bucket is introduced for confidential financials.
- **Membership retention policy** — Phase 1 leaves unpaid signups in the DB indefinitely (admin can soft-delete via `active = false`). Phase 2 should decide whether unpaid signups roll forward each year or get auto-archived after N days. The `active` flag and `year` column support either approach.

---

## Build-plan notes (not schema concerns, but worth carrying forward)

These came up during schema review and aren't database-level fixes, but the Phase 1 build plan should address them:

1. **Trigger error message UX** — the `validate_membership_paid_state` trigger raises `EXCEPTION 'paid=true requires either a payment_id or a $0-priced tier (tier_id=…, price_cents=…)'`. Useful for debugging, ugly if it ever surfaces to an admin in the UI. The admin memberships edit endpoint should catch this specific Postgres error code and translate to a user-friendly message like "Cannot mark this membership as paid without recording a payment first."
2. **Stripe webhook idempotency** — see the payments table comments. Webhook handler must use `ON CONFLICT (stripe_session_id) DO UPDATE WHERE status != 'succeeded'` or equivalent to handle Stripe's delivery retries.
3. **Memberships admin list filter default** — default filter is `year = current_year`, NOT `active = true`. Soft-deleted rows still show in the current-year view so admins can un-delete (trash-can pattern). Year rollover is a separate filter, not an `active` toggle.
