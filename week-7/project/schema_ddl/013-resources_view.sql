BEGIN;

DROP VIEW IF EXISTS resources_view CASCADE;
CREATE VIEW resources_view AS
SELECT user_role_resource_access_view.resource_id
     , resources.type
     , coalesce(folders.id, files.id)                             AS id
     , coalesce(folders.name, files.name)                         AS name
     , coalesce(folders.parent_folder_id, files.parent_folder_id) AS parent_folder_id
     , files.mime_type
     , files.size
     , files.storage_path
     , resources.created_at
     , resources.updated_at
     , resources.created_by
     , resources.updated_by
     , user_role_resource_access_view.user_id
     , user_role_resource_access_view.role_id
     , user_role_resource_access_view.role
     , user_role_resource_access_view.manage
     , user_role_resource_access_view.read
     , user_role_resource_access_view.write
     , user_role_resource_access_view.delete
  FROM user_role_resource_access_view
      JOIN resources ON user_role_resource_access_view.resource_id = resources.id
      FULL OUTER JOIN files ON resources.id = files.resource_id
      FULL OUTER JOIN folders ON resources.id = folders.resource_id;


COMMENT ON VIEW resources_view IS 'Resources view; a consolidated view of all resources with their respective metadata and access control information';
COMMENT ON COLUMN resources_view.resource_id IS 'Resource ID';
COMMENT ON COLUMN resources_view.type IS 'Resource type';
COMMENT ON COLUMN resources_view.id IS 'internal ID of the resource: (file or folder id)';
COMMENT ON COLUMN resources_view.name IS 'Resource name';
COMMENT ON COLUMN resources_view.parent_folder_id IS 'Parent folder ID';
COMMENT ON COLUMN resources_view.mime_type IS 'MIME type of the file or Null for folders';
COMMENT ON COLUMN resources_view.size IS 'Size of the file or Null for folders';
COMMENT ON COLUMN resources_view.storage_path IS 'Storage path of the file or Null for folders';
COMMENT ON COLUMN resources_view.created_at IS 'Resource creation timestamp';
COMMENT ON COLUMN resources_view.updated_at IS 'Resource last update timestamp';
COMMENT ON COLUMN resources_view.created_by IS 'Resource creator id (user_id)';
COMMENT ON COLUMN resources_view.updated_by IS 'Resource last updater id (user_id)';
COMMENT ON COLUMN resources_view.user_id IS 'User ID';
COMMENT ON COLUMN resources_view.role_id IS 'Role ID';
COMMENT ON COLUMN resources_view.role IS 'Role name';
COMMENT ON COLUMN resources_view.manage IS 'can manage the resource';
COMMENT ON COLUMN resources_view.read IS 'can read the resource';
COMMENT ON COLUMN resources_view.write IS 'can write the resource';
COMMENT ON COLUMN resources_view.delete IS 'can delete the resource';

COMMIT;
