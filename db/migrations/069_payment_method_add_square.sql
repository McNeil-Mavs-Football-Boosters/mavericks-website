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
