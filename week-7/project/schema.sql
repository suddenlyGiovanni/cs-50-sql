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
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    role_name TEXT NOT NULL UNIQUE CHECK ( role_name IN ('admin', 'owner', 'contributor', 'viewer') )
);

DROP INDEX IF EXISTS roles_role_name_index;
CREATE INDEX IF NOT EXISTS roles_role_name_index ON roles(id, role_name);


INSERT INTO roles (role_name)
VALUES ('admin')       -- can change ownership and manage permissions
     , ('owner')       -- can read, write, delete and manage permissions
     , ('contributor') -- can read, write but not delete or manage permissions
     , ('viewer'); -- can only read


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
    FOREIGN KEY (parent_folder_id) REFERENCES folders(id)
        ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (updated_by) REFERENCES users(id)
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
    FOREIGN KEY (parent_folder_id) REFERENCES folders(id)
        ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (updated_by) REFERENCES users(id)
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
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    role_id         INTEGER NOT NULL,
    user_id         INTEGER NOT NULL,
    folder_id       INTEGER DEFAULT NULL,
    file_id         INTEGER DEFAULT NULL,
    permission_type TEXT    NOT NULL CHECK ( permission_type IN ('read', 'write', 'delete', 'manage') ),
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    FOREIGN KEY (folder_id) REFERENCES folders(id)
        ON DELETE CASCADE,
--     foreign key (file_id) references files(id) ON DELETE CASCADE
    UNIQUE (user_id, folder_id, file_id),
    CHECK ( folder_id IS NOT NULL OR file_id IS NOT NULL )
);
