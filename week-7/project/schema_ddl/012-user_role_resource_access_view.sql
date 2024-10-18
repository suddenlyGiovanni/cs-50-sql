BEGIN;

DROP VIEW IF EXISTS user_role_resource_access_view CASCADE;

CREATE OR REPLACE VIEW user_role_resource_access_view AS
SELECT user_role_resource.*
     , role_permissions_matrix_view.role
     , role_permissions_matrix_view.manage
     , role_permissions_matrix_view.read
     , role_permissions_matrix_view.write
     , role_permissions_matrix_view.delete
  FROM user_role_resource
      JOIN role_permissions_matrix_view ON user_role_resource.role_id = role_permissions_matrix_view.role_id;

COMMENT ON VIEW user_role_resource_access_view IS 'User-Role-Resource access view';
COMMENT ON COLUMN user_role_resource_access_view.role IS 'Role name';
COMMENT ON COLUMN user_role_resource_access_view.manage IS 'can manage the resource';
COMMENT ON COLUMN user_role_resource_access_view.read IS 'can read the resource';
COMMENT ON COLUMN user_role_resource_access_view.write IS 'can write the resource';
COMMENT ON COLUMN user_role_resource_access_view.delete IS 'can delete the resource';

COMMIT;
