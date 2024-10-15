DROP VIEW IF EXISTS active_users;
CREATE VIEW active_users AS
SELECT id
     , username
     , email
     , hashed_password
     , created_at
  FROM users
 WHERE deleted = FALSE;
