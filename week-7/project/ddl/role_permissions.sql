-- Role-Permission mapping: Many-to-Many relationship
DROP TABLE IF EXISTS role_permissions;
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id       INTEGER NOT NULL,
    permission_id INTEGER NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id)
        ON DELETE CASCADE
);


DROP TRIGGER IF EXISTS role_permissions_role_id_index;
CREATE INDEX IF NOT EXISTS role_permissions_role_id_index ON role_permissions(role_id, permission_id);

  WITH admin_role_id AS (
                        SELECT id
                          FROM roles
                         WHERE name = 'admin'
                        )
     , permissions_ids AS (
                        SELECT id, name FROM permissions WHERE name IN ('read', 'write', 'delete', 'manage')
                        )
INSERT
  INTO role_permissions (role_id, permission_id)
SELECT admin_role_id.id, permissions_ids.id
  FROM admin_role_id
     , permissions_ids;


  WITH owner_role_id AS (
                        SELECT id
                          FROM roles
                         WHERE name = 'owner'
                        )
     , permissions_ids AS (
                        SELECT id, name FROM permissions WHERE name IN ('read', 'write', 'delete')
                        )
INSERT
  INTO role_permissions (role_id, permission_id)
SELECT owner_role_id.id, permissions_ids.id
  FROM owner_role_id
     , permissions_ids;


  WITH editor_role_id AS (
                         SELECT id
                           FROM roles
                          WHERE name = 'editor'
                         )
     , permissions_ids AS (
                         SELECT id, name
                           FROM permissions
                          WHERE name IN ('read', 'write')
                         )
INSERT
  INTO role_permissions (role_id, permission_id)
SELECT editor_role_id.id, permissions_ids.id
  FROM editor_role_id
     , permissions_ids;

  WITH viewer_role_id AS (
                         SELECT id
                           FROM roles
                          WHERE name = 'viewer'
                         )
     , permissions_ids AS (
                         SELECT id, name
                           FROM permissions
                          WHERE name IN ('read')
                         )
INSERT
  INTO role_permissions (role_id, permission_id)
SELECT viewer_role_id.id, permissions_ids.id
  FROM viewer_role_id
     , permissions_ids;
