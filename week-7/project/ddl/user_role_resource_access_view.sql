DROP VIEW IF EXISTS user_role_resource_access_view;

CREATE OR REPLACE VIEW user_role_resource_access_view AS
SELECT user_role_resource.*
     , role_permissions_matrix.role
     , role_permissions_matrix.manage
     , role_permissions_matrix.read
     , role_permissions_matrix.write
     , role_permissions_matrix.delete
  FROM user_role_resource
      JOIN role_permissions_matrix ON user_role_resource.role_id = role_permissions_matrix.role_id;

COMMENT ON VIEW user_role_resource_access_view IS 'User-Role-Resource access view';
COMMENT ON COLUMN user_role_resource_access_view.role IS 'Role name';
COMMENT ON COLUMN user_role_resource_access_view.manage IS 'can manage the resource';
COMMENT ON COLUMN user_role_resource_access_view.read IS 'can read the resource';
COMMENT ON COLUMN user_role_resource_access_view.write IS 'can write the resource';
COMMENT ON COLUMN user_role_resource_access_view.delete IS 'can delete the resource';
