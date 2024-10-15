DROP TABLE IF EXISTS permissions;
CREATE TABLE IF NOT EXISTS permissions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL CHECK ( name IN ('read', 'write', 'delete', 'manage') ) UNIQUE,
    description TEXT NOT NULL
);

DROP INDEX IF EXISTS permissions_permission_name_index;
CREATE INDEX IF NOT EXISTS permissions_permission_name_index ON permissions(id, name);

INSERT INTO permissions (name, description)
VALUES ('read', 'Can READ a resource, Folder or File')
     , ('write', 'Can UPDATE a resource, Folder or File')
     , ('delete', 'Can DELETE a resource, Folder or File')
     , ('manage', 'Can change the access control of a resource, File or Folder');

-- Prevent UPDATES
DROP TRIGGER IF EXISTS prevent_update_permissions;
CREATE TRIGGER prevent_update_permissions
    BEFORE UPDATE
    ON permissions
BEGIN
    SELECT raise(ABORT, 'Modifications to the permissions table are not allowed.');
END;

-- Prevent DELETES
DROP TRIGGER IF EXISTS prevent_delete_permissions;
CREATE TRIGGER prevent_delete_permissions
    BEFORE DELETE
    ON permissions
BEGIN
    SELECT raise(ABORT, 'Deletions from the permissions table are not allowed.');
END;

-- Prevent additional INSERTS
DROP TRIGGER IF EXISTS prevent_insert_permissions;
CREATE TRIGGER prevent_insert_permissions
    BEFORE INSERT
    ON permissions
    WHEN (
         SELECT count(*)
           FROM permissions
         ) > 0
BEGIN
    SELECT raise(ABORT, 'Additional inserts to the permissions table are not allowed.');
END;
