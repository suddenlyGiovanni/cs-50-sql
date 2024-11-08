-- Drop all tables

DROP TABLE IF EXISTS virtual_file_system.public.files CASCADE;
DROP TABLE IF EXISTS virtual_file_system.public.folders CASCADE;
DROP TABLE IF EXISTS virtual_file_system.public.permissions CASCADE;
DROP TABLE IF EXISTS virtual_file_system.public.resources CASCADE;
DROP TABLE IF EXISTS virtual_file_system.public.roles CASCADE;
DROP TABLE IF EXISTS virtual_file_system.public.users CASCADE;
DROP TABLE IF EXISTS virtual_file_system.public.role_permissions CASCADE;
DROP TABLE IF EXISTS virtual_file_system.public.user_role_resource CASCADE;

DROP TYPE IF EXISTS virtual_file_system.public.RESOURCE_TYPE CASCADE;
DROP TYPE IF EXISTS virtual_file_system.public.ROLE_TYPE CASCADE;
DROP TYPE IF EXISTS virtual_file_system.public.PERMISSION_TYPE CASCADE;


-- Drop dangling functions
DROP FUNCTION IF EXISTS virtual_file_system.public.permissions_seal();
DROP FUNCTION IF EXISTS virtual_file_system.public.resource_update_timestamp();
DROP FUNCTION IF EXISTS virtual_file_system.public.resource_assign_owner_role_on_creation();
DROP FUNCTION IF EXISTS virtual_file_system.public.roles_seal();
DROP FUNCTION IF EXISTS virtual_file_system.public.users_prevent_created_at_update();
DROP FUNCTION IF EXISTS virtual_file_system.public.users_soft_delete();
DROP FUNCTION IF EXISTS virtual_file_system.public.prevent_folders_circular_dependency();
DROP FUNCTION IF EXISTS virtual_file_system.public.mkdir();
DROP FUNCTION IF EXISTS virtual_file_system.public.chmod();
DROP FUNCTION IF EXISTS virtual_file_system.public.validate_file_parent_folder_existence();
DROP FUNCTION IF EXISTS virtual_file_system.public.validate_parent_folder_existence();
DROP FUNCTION IF EXISTS virtual_file_system.public.validate_parent_folder_id();

VACUUM;
