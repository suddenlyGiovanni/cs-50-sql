BEGIN;

DROP TABLE IF EXISTS folders CASCADE;

CREATE TABLE IF NOT EXISTS folders (
    id               SERIAL PRIMARY KEY,
    resource_id      INTEGER      NOT NULL UNIQUE,
    parent_folder_id INTEGER DEFAULT NULL CHECK ( parent_folder_id != id ) REFERENCES folders
        ON DELETE CASCADE,
    name             VARCHAR(255) NOT NULL,
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE
);

COMMENT ON TABLE folders IS 'Folders are a kind of specialized resources that represent the hierarchical folders structure. The parent-child relationship is defined by a self-referencing foreign key for the subfolders';
COMMENT ON COLUMN folders.id IS 'Folder ID';
COMMENT ON COLUMN folders.resource_id IS 'Reference to the resource table';
COMMENT ON COLUMN folders.name IS 'Folder name; has to be unique within the parent folder';
COMMENT ON COLUMN folders.parent_folder_id IS 'Reference to the parent folder; NULL by default for top level folders; A Folder cannot be its own parent';


DROP INDEX IF EXISTS folders_resource_id_index;
CREATE INDEX IF NOT EXISTS folders_resource_id_index ON folders(resource_id);
COMMENT ON INDEX folders_resource_id_index IS 'Index to enable fast lookups for the resource_id column';

DROP INDEX IF EXISTS folders_parent_folder_name_unique_idx;
CREATE UNIQUE INDEX folders_parent_folder_name_unique_idx ON folders(parent_folder_id, name);
COMMENT ON INDEX folders_parent_folder_name_unique_idx IS 'Unique index to enforce the unique folder name within the parent folder; Enables fast lookups for the folder name within the parent folder';



CREATE OR REPLACE FUNCTION prevent_folders_circular_dependency() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
BEGIN
    -- Recursively check the parent chain to ensure there's no circular dependency
    IF exists (
              WITH RECURSIVE folder_ancestors AS (
                                                 SELECT parent_folder_id
                                                   FROM folders
                                                  WHERE folders.id = new.parent_folder_id
                                                  UNION ALL
                                                 SELECT folders.parent_folder_id
                                                   FROM folders
                                                       INNER JOIN folder_ancestors ON folders.id = folder_ancestors.parent_folder_id
                                                 )
            SELECT 1
              FROM folders
             WHERE folders.parent_folder_id = new.id
              ) THEN
        RAISE EXCEPTION 'Circular dependency detected: folder id "%" cannot be its own ancestor', new.id;
    END IF;
    RETURN new;
END;
$$;
COMMENT ON FUNCTION prevent_folders_circular_dependency IS 'Prevent circular dependency in the folders table';


CREATE OR REPLACE TRIGGER prevent_circular_dependency_trigger
    BEFORE INSERT OR UPDATE OF parent_folder_id
    ON folders
    FOR EACH ROW
EXECUTE FUNCTION prevent_folders_circular_dependency();


COMMIT;
