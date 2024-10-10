-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it
DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    username   TEXT    NOT NULL UNIQUE,
    email      TEXT    NOT NULL UNIQUE,
    password   TEXT    NOT NULL,
    role       TEXT    NOT NULL CHECK ( role IN ('user', 'admin', 'root') ) DEFAULT 'user',
    created_at TEXT    NOT NULL                                             DEFAULT current_timestamp,
    deleted    INTEGER NOT NULL CHECK ( deleted IN (TRUE, FALSE) )          DEFAULT FALSE
);

DROP INDEX IF EXISTS users_username_index;
CREATE INDEX IF NOT EXISTS users_username_index ON users(id, username);

DROP INDEX IF EXISTS users_role_index;
CREATE INDEX IF NOT EXISTS users_role_index ON users(id, role);


DROP VIEW IF EXISTS users_active;
CREATE VIEW IF NOT EXISTS users_active AS
SELECT id
     , username
     , email
     , password
     , role
     , created_at
  FROM users
 WHERE deleted = FALSE;


DROP TRIGGER IF EXISTS users_delete_trigger;
CREATE TRIGGER IF NOT EXISTS users_delete_trigger
    BEFORE DELETE
    ON users
    FOR EACH ROW
BEGIN
    UPDATE users SET deleted = TRUE WHERE id = old.id;
    -- Prevent the deletion
    SELECT raise(IGNORE);
END;


DROP TABLE IF EXISTS folders;
-- Folders represent the hierarchical folders structure.
-- The parent-child relationship is defined by a self-referencing foreign key for the subfolders
CREATE TABLE IF NOT EXISTS folders (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    name             TEXT    NOT NULL,                           -- Folder name
    parent_folder_id INTEGER,                                    -- Reference to the parent folder can be NULL if it's a root folder
    owner_id         INTEGER NOT NULL,                           -- Reference to the user who owns the folder
    created_at       TEXT    NOT NULL DEFAULT current_timestamp, -- Folder creation timestamp
    updated_at       TEXT    NOT NULL DEFAULT current_timestamp, -- Folder last update timestamp
    FOREIGN KEY (parent_folder_id) REFERENCES folders(id)
        ON DELETE CASCADE,
    FOREIGN KEY (owner_id) REFERENCES users(id)
        ON DELETE CASCADE
);


-- Folder name must have a unique name within the parent folder, not globally: I need to create a trigger that checks this constraint
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
