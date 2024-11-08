-- Drop all tables

DROP TABLE virtual_file_system.public.files CASCADE;
DROP TABLE virtual_file_system.public.folders CASCADE;
DROP TABLE virtual_file_system.public.permissions CASCADE;
DROP TABLE virtual_file_system.public.resources CASCADE;
DROP TABLE virtual_file_system.public.roles CASCADE;
DROP TABLE virtual_file_system.public.users CASCADE;
DROP TABLE virtual_file_system.public.role_permissions CASCADE;
DROP TABLE virtual_file_system.public.user_role_resource CASCADE;

DROP TYPE virtual_file_system.public.RESOURCE_TYPE CASCADE;
DROP TYPE virtual_file_system.public.ROLE_TYPE CASCADE;
DROP TYPE virtual_file_system.public.PERMISSION_TYPE CASCADE;


-- Drop dangling functions
DROP FUNCTION virtual_file_system.public.permissions_seal();
DROP FUNCTION virtual_file_system.public.resources_validate_folders_circular_dependency();
DROP FUNCTION virtual_file_system.public.resources_validate_parent_folder_id();
DROP FUNCTION virtual_file_system.public.resource_update_timestamp();
DROP FUNCTION virtual_file_system.public.roles_seal();
DROP FUNCTION virtual_file_system.public.users_prevent_created_at_update();
DROP FUNCTION virtual_file_system.public.users_soft_delete();
DROP FUNCTION virtual_file_system.public.mkdir();
DROP FUNCTION virtual_file_system.public.chmod();

VACUUM;
