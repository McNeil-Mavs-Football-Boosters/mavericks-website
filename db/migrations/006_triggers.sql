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
