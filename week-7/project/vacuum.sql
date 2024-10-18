-- Drop all tables

DROP TABLE IF EXISTS files CASCADE;
DROP TABLE IF EXISTS folders CASCADE;
DROP TABLE IF EXISTS permissions CASCADE;
DROP TABLE IF EXISTS resources CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS users CASCADE;


-- Drop dangling functions
DROP FUNCTION IF EXISTS files_validate_unique_name();
DROP FUNCTION IF EXISTS folders_validate_unique_name();
DROP FUNCTION IF EXISTS permissions_seal();
DROP FUNCTION IF EXISTS resource_update_timestamp();
DROP FUNCTION IF EXISTS roles_seal();
DROP FUNCTION IF EXISTS users_prevent_created_at_update();
DROP FUNCTION IF EXISTS users_soft_delete();


VACUUM;
