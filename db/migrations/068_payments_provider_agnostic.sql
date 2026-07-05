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
