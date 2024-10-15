-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it

DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    username        TEXT     NOT NULL UNIQUE,                                                       -- unique username
    email           TEXT     NOT NULL UNIQUE,                                                       -- unique email
    hashed_password TEXT     NOT NULL,                                                              -- hashed password
    created_at      DATETIME NOT NULL                                    DEFAULT current_timestamp, -- READONLY User creation timestamp, auto-generated on creation
    deleted         INTEGER  NOT NULL CHECK ( deleted IN (TRUE, FALSE) ) DEFAULT FALSE              -- soft delete flag
);


DROP INDEX IF EXISTS users_username_index;
CREATE INDEX IF NOT EXISTS users_username_index ON users(username);

DROP INDEX IF EXISTS users_deleted_index;
CREATE INDEX IF NOT EXISTS users_deleted_index ON users(deleted);

DROP TRIGGER IF EXISTS users_prevent_created_at_update_trigger;
CREATE TRIGGER IF NOT EXISTS users_prevent_created_at_update_trigger
    BEFORE UPDATE
    ON users
    FOR EACH ROW
    WHEN new.created_at != old.created_at
BEGIN
    SELECT raise(ABORT, 'The created_at column is read-only and cannot be updated.');
END;

-- user soft delete trigger
DROP TRIGGER IF EXISTS users_soft_delete_trigger;
CREATE TRIGGER IF NOT EXISTS users_soft_delete_trigger
    BEFORE DELETE
    ON users
    FOR EACH ROW
BEGIN
    UPDATE users SET deleted = TRUE WHERE id = old.id;
    -- Prevent the deletion
    SELECT raise(IGNORE);
END;


DROP VIEW IF EXISTS active_users;
CREATE VIEW IF NOT EXISTS active_users AS
SELECT id
     , username
     , email
     , hashed_password
     , created_at
  FROM users
 WHERE deleted = FALSE;


-- Roles are granted different permission to resources (file or folder)
DROP TABLE IF EXISTS roles;
CREATE TABLE IF NOT EXISTS roles (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL UNIQUE CHECK ( name IN ('admin', 'owner', 'editor', 'viewer') ),
    description TEXT NOT NULL
);

DROP INDEX IF EXISTS roles_role_name_index;
CREATE INDEX IF NOT EXISTS roles_role_name_index ON roles(id, name);


INSERT INTO roles (name, description)
VALUES ('admin', 'Has FULL CONTROL over all files and folders, including the ability to MODIFY PERMISSIONS.')
     , ('owner', 'Can READ, WRITE and DELETE the resource; Automatically assigned to the user creating said resource')
     , ('editor', 'Can READ and WRITE but not delete or manage permissions')
     , ('viewer', 'Can only VIEW the resource');


-- Defines the type of resource: folder or file
DROP TABLE IF EXISTS resources;
CREATE TABLE IF NOT EXISTS resources (
    id   INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    type TEXT    NOT NULL CHECK ( type IN ('folder', 'file') )
);

DROP INDEX IF EXISTS resources_type_index;
CREATE INDEX IF NOT EXISTS resources_type_index ON resources(type);


DROP TABLE IF EXISTS folders;
-- Folders represent the hierarchical folders structure.
-- The parent-child relationship is defined by a self-referencing foreign key for the subfolders
CREATE TABLE IF NOT EXISTS folders (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    name             TEXT     NOT NULL,                           -- Folder name
    parent_folder_id INTEGER           DEFAULT NULL,              -- Reference to the parent folder can be NULL if it's a root folder
    created_at       DATETIME NOT NULL DEFAULT current_timestamp, -- READONLY Folder creation timestamp, auto-generated on creation
    updated_at       DATETIME NOT NULL DEFAULT current_timestamp, -- Folder last update timestamp, auto-updated on every update, please omit this field in the INSERT and UPDATE statements
    created_by       INTEGER  NOT NULL,                           -- READONLY Reference to the user who owns the folder
    updated_by       INTEGER  NOT NULL,                           -- Reference to the user who last updated the folder
    resource_id      INTEGER  NOT NULL UNIQUE,                    -- Reference to the resource table
    FOREIGN KEY (parent_folder_id) REFERENCES folders(id)
        ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (updated_by) REFERENCES users(id),
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE

);

DROP TRIGGER IF EXISTS folders_name_unique_within_parent;
CREATE TRIGGER IF NOT EXISTS folders_name_unique_within_parent
    BEFORE INSERT
    ON folders
    FOR EACH ROW
BEGIN
    SELECT raise(ABORT, 'Folder name must be unique within the parent folder')
     WHERE exists (
                  SELECT 1 FROM folders f WHERE f.parent_folder_id = new.parent_folder_id AND f.name = new.name
                  );
END;

CREATE TRIGGER IF NOT EXISTS folders_updated_at_trigger
    AFTER UPDATE
    ON folders
    FOR EACH ROW
BEGIN
    UPDATE folders SET updated_at = current_timestamp WHERE id = new.id;
END;



DROP TABLE IF EXISTS files;
CREATE TABLE IF NOT EXISTS files (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    name             TEXT     NOT NULL,                           -- unique file name within the parent folder
    content_url      TEXT     NOT NULL,                           -- URL reference to the file
    parent_folder_id INTEGER  NOT NULL,                           -- Reference to the parent folder
    metadata         TEXT,                                        -- JSON metadata
    created_at       DATETIME NOT NULL DEFAULT current_timestamp, -- READONLY, auto-generated on creation
    updated_at       DATETIME NOT NULL DEFAULT current_timestamp, -- READONLY, auto-updated on every update, please omit this field in the INSERT and UPDATE statements
    created_by       INTEGER  NOT NULL,                           -- READONLY, reference to the user who created the file
    updated_by       INTEGER  NOT NULL,                           -- reference to the user who last updated the file
    resource_id      INTEGER  NOT NULL UNIQUE,                    -- Reference to the resource table
    FOREIGN KEY (parent_folder_id) REFERENCES folders(id)
        ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (updated_by) REFERENCES users(id),
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE

);

DROP INDEX IF EXISTS files_parent_folder_id_index;
CREATE INDEX IF NOT EXISTS files_parent_folder_id_index ON files(parent_folder_id);

DROP TRIGGER IF EXISTS files_name_unique_within_parent;
CREATE TRIGGER IF NOT EXISTS files_name_unique_within_parent
    BEFORE INSERT
    ON files
    FOR EACH ROW
BEGIN
    SELECT raise(ABORT, 'File name must be unique within the parent folder')
     WHERE exists (
                  SELECT 1 FROM files f WHERE f.parent_folder_id = new.parent_folder_id AND f.name = new.name
                  );
END;

CREATE TRIGGER IF NOT EXISTS files_updated_at_trigger
    AFTER UPDATE
    ON files
    FOR EACH ROW
BEGIN
    UPDATE files SET updated_at = current_timestamp WHERE id = new.id;
END;



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



DROP TABLE IF EXISTS user_role_resource;
CREATE TABLE IF NOT EXISTS user_role_resource (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL,
    role_id     INTEGER NOT NULL,
    resource_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE

);
