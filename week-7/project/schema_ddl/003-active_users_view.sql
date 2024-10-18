BEGIN;
DROP VIEW IF EXISTS active_users_view CASCADE;

CREATE VIEW active_users_view AS
SELECT id
     , username
     , email
     , hashed_password
     , created_at
  FROM users
 WHERE deleted = FALSE;

COMMIT;
