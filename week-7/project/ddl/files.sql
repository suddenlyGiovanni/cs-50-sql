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

DROP TRIGGER IF EXISTS files_updated_at_trigger;
CREATE TRIGGER IF NOT EXISTS files_updated_at_trigger
    AFTER UPDATE
    ON files
    FOR EACH ROW
BEGIN
    UPDATE files SET updated_at = current_timestamp WHERE id = new.id;
END;
