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
