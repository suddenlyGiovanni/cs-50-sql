DROP VIEW IF EXISTS role_permissions_matrix;
CREATE VIEW IF NOT EXISTS role_permissions_matrix AS
SELECT r.name   AS role
     , max(CASE WHEN p.name = 'manage' THEN TRUE
                                       ELSE FALSE
           END) AS manage
     , max(CASE WHEN p.name = 'read' THEN TRUE
                                     ELSE FALSE
           END) AS read
     , max(CASE WHEN p.name = 'write' THEN TRUE
                                      ELSE FALSE
           END) AS write
     , max(CASE WHEN p.name = 'delete' THEN TRUE
                                       ELSE FALSE
           END) AS "delete"
  FROM role_permissions rp
      JOIN roles        r ON rp.role_id = r.id
      JOIN permissions  p ON rp.permission_id = p.id
 GROUP BY r.name
 ORDER BY r.id ASC;
