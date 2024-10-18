BEGIN;

DROP VIEW IF EXISTS role_permissions_matrix_view CASCADE;

CREATE OR REPLACE VIEW role_permissions_matrix_view AS
SELECT r.name                     AS role
     , rp.role_id                 AS role_id
     , bool_or(p.name = 'read')   AS read
     , bool_or(p.name = 'write')  AS write
     , bool_or(p.name = 'delete') AS delete
     , bool_or(p.name = 'manage') AS manage
  FROM role_permissions rp
      JOIN roles        r ON r.id = rp.role_id
      JOIN permissions  p ON p.id = rp.permission_id
 GROUP BY rp.role_id
        , r.name
 ORDER BY rp.role_id;

COMMENT ON VIEW role_permissions_matrix_view IS 'Role-Permission matrix view; A role can have multiple permissions and a permission can be assigned to multiple roles';
COMMENT ON COLUMN role_permissions_matrix_view.role IS 'The unique name of the role';
COMMENT ON COLUMN role_permissions_matrix_view.role_id IS 'Reference to the role table';
COMMENT ON COLUMN role_permissions_matrix_view.read IS 'Can READ a resource, Folder or File';
COMMENT ON COLUMN role_permissions_matrix_view.write IS 'Can UPDATE a resource, Folder or File';
COMMENT ON COLUMN role_permissions_matrix_view.delete IS 'Can DELETE a resource, Folder or File';
COMMENT ON COLUMN role_permissions_matrix_view.manage IS 'Can change the access control of a resource, File or Folder';

COMMIT;
