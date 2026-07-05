-- 069_rollback.sql
-- Reverses 069_payment_method_add_square.sql.
--
-- NOTE: Postgres has no `ALTER TYPE ... DROP VALUE`. Removing 'square' from the
-- enum would require recreating payment_method_type and rewriting every column
-- that uses it. Since the value is additive and harmless (nothing breaks if it
-- exists unused), this rollback is intentionally a no-op. If a true removal is
-- ever required, recreate the type: create a new enum without 'square', ALTER
-- the payments.method column to it via USING, then drop the old type.

-- (no-op)
SELECT 1;
