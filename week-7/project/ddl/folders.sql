DROP TABLE IF EXISTS folders;
DROP INDEX IF EXISTS folders_resource_id_index;
DROP INDEX IF EXISTS folders_parent_folder_id_index;
DROP TRIGGER IF EXISTS folders_name_unique_within_parent_trigger ON folders;
DROP TRIGGER IF EXISTS folders_updated_at_trigger ON folders;


CREATE TABLE IF NOT EXISTS folders (
    id               SERIAL PRIMARY KEY,
    resource_id      INTEGER      NOT NULL UNIQUE,
    name             VARCHAR(255) NOT NULL,
    parent_folder_id INTEGER               DEFAULT NULL REFERENCES folders
        ON DELETE CASCADE,
    created_at       TIMESTAMP    NOT NULL DEFAULT current_timestamp,
    updated_at       TIMESTAMP    NOT NULL DEFAULT current_timestamp,
    created_by       INTEGER      NOT NULL,
    updated_by       INTEGER      NOT NULL,
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (updated_by) REFERENCES users(id)
);

COMMENT ON TABLE folders IS 'Folders are a kind of specialized resources that represent the hierarchical folders structure. The parent-child relationship is defined by a self-referencing foreign key for the subfolders';
COMMENT ON COLUMN folders.id IS 'Folder ID';
COMMENT ON COLUMN folders.resource_id IS 'Reference to the resource table';
COMMENT ON COLUMN folders.name IS 'Folder name; has to be unique within the parent folder';
COMMENT ON COLUMN folders.parent_folder_id IS 'Reference to the parent folder; NULL by default for top level folders';
COMMENT ON COLUMN folders.created_at IS 'Folder creation timestamp; auto-generated on creation';
COMMENT ON COLUMN folders.updated_at IS 'Folder last update timestamp; auto-updated on every update';
COMMENT ON COLUMN folders.created_by IS 'Reference to the user who owns the folder';
COMMENT ON COLUMN folders.updated_by IS 'Reference to the user who last updated the folder';


CREATE INDEX IF NOT EXISTS folders_resource_id_index ON folders(resource_id);



CREATE INDEX IF NOT EXISTS folders_parent_folder_id_index ON folders(parent_folder_id);


CREATE OR REPLACE FUNCTION validate_unique_folder_name() RETURNS TRIGGER AS
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


CREATE TRIGGER folders_name_unique_within_parent_trigger
    BEFORE INSERT
    ON folders
    FOR EACH ROW
EXECUTE FUNCTION validate_unique_folder_name();



CREATE OR REPLACE FUNCTION folders_update_timestamp() RETURNS TRIGGER AS
$$
BEGIN
    new.updated_at = current_timestamp;
    RETURN new;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER folders_updated_at_trigger
    BEFORE UPDATE
    ON folders
    FOR EACH ROW
EXECUTE FUNCTION folders_update_timestamp();
