-- Migration 028: replace .example.com placeholder URLs from 027 with real
-- MaxPreps and venue URLs. Throwaway test data; admin CRUD will replace these
-- rows entirely (Step 7b or 13). Convention: opponent_url points to the
-- opponent's MaxPreps team page.

BEGIN;

UPDATE games
SET opponent_url = 'https://www.maxpreps.com/tx/round-rock/round-rock-dragons/football/'
WHERE year = '2026-27'
  AND team_level = 'varsity'
  AND opponent = 'Round Rock'
  AND opponent_url = 'https://roundrockfootball.example.com/';

COMMIT;
