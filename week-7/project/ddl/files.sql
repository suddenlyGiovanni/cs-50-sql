BEGIN;

DROP TABLE IF EXISTS files CASCADE;
DROP INDEX IF EXISTS files_resource_id_index;
CREATE TABLE IF NOT EXISTS files (
    id               SERIAL PRIMARY KEY,
    resource_id      INTEGER      NOT NULL UNIQUE,
    parent_folder_id INTEGER      NOT NULL,
    name             VARCHAR(255) NOT NULL,
    mime_type        VARCHAR(255) NOT NULL,
    size             BIGINT       NOT NULL DEFAULT 0,
    storage_path     TEXT         NOT NULL,
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE,
    FOREIGN KEY (parent_folder_id) REFERENCES folders(id)
        ON DELETE CASCADE
);

DROP TRIGGER IF EXISTS files_name_unique_within_parent_trigger ON files;

COMMENT ON TABLE files IS 'Files are a kind of specialized resources that represent the actual files stored in the system. All Files must exist within a parent folder';
COMMENT ON COLUMN files.id IS 'File ID';
COMMENT ON COLUMN files.resource_id IS 'Reference to the resource table';
COMMENT ON COLUMN files.parent_folder_id IS 'Reference to the parent folder';
COMMENT ON COLUMN files.name IS 'File name; has to be unique within the parent folder';
COMMENT ON COLUMN files.mime_type IS 'File MIME type; e.g. application/pdf, image/jpeg, etc.';
COMMENT ON COLUMN files.size IS 'File size in bytes';
COMMENT ON COLUMN files.storage_path IS 'URL reference to the file; e.g., S3 URL';


CREATE INDEX IF NOT EXISTS files_parent_folder_id_index ON files(parent_folder_id);
CREATE INDEX IF NOT EXISTS files_resource_id_index ON files(resource_id);


CREATE OR REPLACE FUNCTION files_validate_unique_name() RETURNS TRIGGER AS
$$
BEGIN
    IF exists(
             SELECT 1 FROM files WHERE new.parent_folder_id = files.parent_folder_id AND files.name = new.name
             ) THEN
        RAISE EXCEPTION 'Files name must be unique within the parent folder';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER files_name_unique_within_parent_trigger
    BEFORE INSERT
    ON files
    FOR EACH ROW
EXECUTE FUNCTION files_validate_unique_name();

COMMIT;
