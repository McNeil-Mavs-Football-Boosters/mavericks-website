-- Migration 015: touch_updated_at triggers for the new football-pivot tables

CREATE TRIGGER touch_games BEFORE UPDATE ON games FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_rosters BEFORE UPDATE ON rosters FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_coaches BEFORE UPDATE ON coaches FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER touch_resource_links BEFORE UPDATE ON resource_links FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
