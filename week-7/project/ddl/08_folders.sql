BEGIN;
DROP TABLE IF EXISTS folders CASCADE;
DROP INDEX IF EXISTS folders_resource_id_index;
DROP INDEX IF EXISTS folders_parent_folder_id_index;
DROP TRIGGER IF EXISTS folders_unique_name_within_parent_trigger ON folders;

CREATE TABLE IF NOT EXISTS folders (
    id               SERIAL PRIMARY KEY,
    resource_id      INTEGER      NOT NULL UNIQUE,
    parent_folder_id INTEGER DEFAULT NULL REFERENCES folders
        ON DELETE CASCADE,
    name             VARCHAR(255) NOT NULL,
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE
);

COMMENT ON TABLE folders IS 'Folders are a kind of specialized resources that represent the hierarchical folders structure. The parent-child relationship is defined by a self-referencing foreign key for the subfolders';
COMMENT ON COLUMN folders.id IS 'Folder ID';
COMMENT ON COLUMN folders.resource_id IS 'Reference to the resource table';
COMMENT ON COLUMN folders.name IS 'Folder name; has to be unique within the parent folder';
COMMENT ON COLUMN folders.parent_folder_id IS 'Reference to the parent folder; NULL by default for top level folders';


CREATE INDEX IF NOT EXISTS folders_resource_id_index ON folders(resource_id);
CREATE INDEX IF NOT EXISTS folders_parent_folder_id_index ON folders(parent_folder_id);


CREATE OR REPLACE FUNCTION folders_validate_unique_name() RETURNS TRIGGER AS
$$
BEGIN
    IF exists(
             SELECT 1 FROM folders f WHERE new.parent_folder_id = f.parent_folder_id AND f.name = new.name
             ) THEN
        RAISE EXCEPTION 'Folder name must be unique within the parent folder';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER folders_unique_name_within_parent_trigger
    BEFORE INSERT
    ON folders
    FOR EACH ROW
EXECUTE FUNCTION folders_validate_unique_name();


COMMIT;
