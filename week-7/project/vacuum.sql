DROP VIEW IF EXISTS active_users;

DROP TABLE IF EXISTS files;
DROP INDEX IF EXISTS files_parent_folder_id_index;
DROP TRIGGER IF EXISTS files_name_unique_within_parent;
DROP TRIGGER IF EXISTS files_updated_at_trigger;


DROP TABLE IF EXISTS folders;
DROP INDEX IF EXISTS folders_resource_id_index;
DROP INDEX IF EXISTS folders_parent_folder_id_index;
DROP TRIGGER IF EXISTS folders_updated_at_trigger;
DROP TRIGGER IF EXISTS folders_name_unique_within_parent;


DROP TABLE IF EXISTS permissions;
DROP INDEX IF EXISTS permissions_permission_name_index;
DROP TRIGGER IF EXISTS prevent_update_permissions;
DROP TRIGGER IF EXISTS prevent_delete_permissions;
DROP TRIGGER IF EXISTS prevent_insert_permissions;


DROP TABLE IF EXISTS resources;
DROP INDEX IF EXISTS resources_type_index;


DROP TABLE IF EXISTS role_permissions;
DROP TRIGGER IF EXISTS role_permissions_role_id_index;

DROP VIEW IF EXISTS role_permissions_matrix;

DROP TABLE IF EXISTS roles;
DROP INDEX IF EXISTS roles_role_name_index;

DROP TABLE IF EXISTS user_role_resource;


DROP TABLE IF EXISTS users;
DROP INDEX IF EXISTS users_username_index;
DROP INDEX IF EXISTS users_deleted_index;
DROP TRIGGER IF EXISTS users_prevent_created_at_update_trigger;
DROP TRIGGER IF EXISTS users_soft_delete_trigger;

VACUUM;
