-- 068_rollback.sql
-- Reverses 068_payments_provider_agnostic.sql: restores the stripe_* column names,
-- constraint names, and drops payment_provider. Idempotent.

BEGIN;

ALTER TABLE payments DROP COLUMN IF EXISTS payment_provider;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'payments' AND column_name = 'payment_session_id') THEN
    ALTER TABLE payments RENAME COLUMN payment_session_id TO stripe_session_id;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'payments' AND column_name = 'payment_provider_id') THEN
    ALTER TABLE payments RENAME COLUMN payment_provider_id TO stripe_payment_intent_id;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_payment_session_id_key') THEN
    ALTER TABLE payments RENAME CONSTRAINT payments_payment_session_id_key
      TO payments_stripe_session_id_key;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_payment_provider_id_key') THEN
    ALTER TABLE payments RENAME CONSTRAINT payments_payment_provider_id_key
      TO payments_stripe_payment_intent_id_key;
  END IF;
END $$;

COMMENT ON COLUMN sponsors.payment_id IS
  'Links the sponsor''s inbound Stripe payment to the sponsor record for Treasurer reconciliation. Nullable for manual or legacy entries.';

COMMIT;
