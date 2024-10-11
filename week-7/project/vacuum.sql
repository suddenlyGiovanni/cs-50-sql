DROP VIEW IF EXISTS users_active;
DROP INDEX IF EXISTS users_username_index;
DROP INDEX IF EXISTS users_role_index;
DROP TABLE IF EXISTS users;

DROP TABLE IF EXISTS folders;

DROP TABLE IF EXISTS files;

DROP TABLE IF EXISTS permissions;

VACUUM;
