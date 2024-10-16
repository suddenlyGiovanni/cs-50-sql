-- Role-Permission mapping: Many-to-Many relationship
DROP TABLE IF EXISTS role_permissions;

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id       SMALLINT NOT NULL,
    permission_id SMALLINT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id)
        ON DELETE CASCADE,
    UNIQUE (role_id, permission_id)
);


DROP TRIGGER IF EXISTS role_permissions_role_id_index ON role_permissions;
CREATE INDEX IF NOT EXISTS role_permissions_role_id_index ON role_permissions(role_id, permission_id);

  WITH role_permissions_mapping AS (
                                   SELECT r.id AS role_id, p.id AS permission_id
                                     FROM roles           r
                                         JOIN permissions p
                                         ON ((r.name = 'admin' AND p.name IN ('read', 'write', 'delete', 'manage')) OR
                                             (r.name = 'owner' AND p.name IN ('read', 'write', 'delete')) OR
                                             (r.name = 'editor' AND p.name IN ('read', 'write')) OR
                                             (r.name = 'viewer' AND p.name = 'read'))
                                   )
INSERT
  INTO role_permissions (role_id, permission_id)
SELECT role_id, permission_id
  FROM role_permissions_mapping;
