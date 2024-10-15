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

DROP INDEX IF EXISTS folders_resource_id_index;
CREATE INDEX IF NOT EXISTS folders_resource_id_index ON folders(resource_id);


DROP INDEX IF EXISTS folders_parent_folder_id_index;
CREATE INDEX IF NOT EXISTS folders_parent_folder_id_index ON folders(parent_folder_id);


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

DROP TRIGGER IF EXISTS folders_updated_at_trigger;
CREATE TRIGGER IF NOT EXISTS folders_updated_at_trigger
    AFTER UPDATE
    ON folders
    FOR EACH ROW
BEGIN
    UPDATE folders SET updated_at = current_timestamp WHERE id = new.id;
END;
