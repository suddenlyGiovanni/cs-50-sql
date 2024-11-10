BEGIN;

-- Creation of the folders table
DROP TABLE IF EXISTS folders CASCADE;
CREATE TABLE IF NOT EXISTS folders (
    id          SERIAL PRIMARY KEY,
    resource_id INTEGER      NOT NULL UNIQUE,
    name        VARCHAR(255) NOT NULL,
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE
);

COMMENT ON TABLE folders IS 'Folders are a kind of specialized resources that represent the hierarchical folders structure. The parent-child relationship is defined by a self-referencing foreign key for the subfolders';
COMMENT ON COLUMN folders.id IS 'Folder ID';
COMMENT ON COLUMN folders.resource_id IS 'Reference to the resource table';
COMMENT ON COLUMN folders.name IS 'Folder name; has to be unique within the parent folder';

DROP INDEX IF EXISTS folders_resource_id_index;
-- CREATE INDEX IF NOT EXISTS folders_resource_id_index ON folders(resource_id);
-- COMMENT ON INDEX folders_resource_id_index IS 'Index to enable fast lookups for the resource_id column';

DROP INDEX IF EXISTS folders_parent_folder_name_unique_idx;
-- CREATE UNIQUE INDEX folders_parent_folder_name_unique_idx ON folders(parent_folder_id, name);
-- COMMENT ON INDEX folders_parent_folder_name_unique_idx IS 'Unique index to enforce the unique folder name within the parent folder; Enables fast lookups for the folder name within the parent folder';


COMMIT;
