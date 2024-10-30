BEGIN;

DROP VIEW IF EXISTS role_permissions_matrix_view CASCADE;

CREATE OR REPLACE VIEW role_permissions_matrix_view AS
SELECT roles.name                           AS role
     , role_permissions.role_id             AS role_id
     , bool_or(permissions.name = 'read')   AS read
     , bool_or(permissions.name = 'write')  AS write
     , bool_or(permissions.name = 'delete') AS delete
     , bool_or(permissions.name = 'manage') AS manage
  FROM role_permissions
      JOIN roles ON roles.id = role_permissions.role_id
      JOIN permissions ON permissions.id = role_permissions.permission_id
 GROUP BY role_permissions.role_id
        , roles.name
 ORDER BY role_permissions.role_id;

COMMENT ON VIEW role_permissions_matrix_view IS 'Role-Permission matrix view; A role can have multiple permissions and a permission can be assigned to multiple roles';
COMMENT ON COLUMN role_permissions_matrix_view.role IS 'The unique name of the role';
COMMENT ON COLUMN role_permissions_matrix_view.role_id IS 'Reference to the role table';
COMMENT ON COLUMN role_permissions_matrix_view.read IS 'Can READ a resource, Folder or File';
COMMENT ON COLUMN role_permissions_matrix_view.write IS 'Can UPDATE a resource, Folder or File';
COMMENT ON COLUMN role_permissions_matrix_view.delete IS 'Can DELETE a resource, Folder or File';
COMMENT ON COLUMN role_permissions_matrix_view.manage IS 'Can change the access control of a resource, File or Folder';

COMMIT;
