DROP VIEW IF EXISTS role_permissions_matrix_view;
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
