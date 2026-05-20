-- Rollback for migration 039: restore Wallin to pre-migration values.

UPDATE coaches
SET name = 'Coach Wallin',
    role = 'Position Coach'
WHERE id = 'a4e36da9-6371-4400-a9c7-dbed6ddce0fa';
