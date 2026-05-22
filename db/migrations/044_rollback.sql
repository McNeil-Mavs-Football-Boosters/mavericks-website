-- 044_rollback.sql
-- Restores the original featured = true for the 3 sponsors that migration
-- 041 seeded as featured (Rudy's, AutoNation, Sunflower). Matches the
-- pre-044 state. Note: the carousel sponsor_spotlight tiles still won't
-- come back unless 043 is also rolled back.

begin;

update sponsors
  set featured = true
  where year = '2025-26'
    and name in (
      'Rudy''s BBQ',
      'AutoNation Chevrolet West Austin',
      'Sunflower Bank'
    );

commit;
