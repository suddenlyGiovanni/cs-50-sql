BEGIN;

DROP TABLE IF EXISTS files CASCADE;
DROP INDEX IF EXISTS files_resource_id_index;
DROP TRIGGER IF EXISTS files_name_unique_within_parent ON files;
DROP TRIGGER IF EXISTS files_updated_at_trigger ON files;

CREATE TABLE IF NOT EXISTS files (
    id               SERIAL PRIMARY KEY,
    resource_id      INTEGER      NOT NULL UNIQUE,
    parent_folder_id INTEGER      NOT NULL,
    name             VARCHAR(255) NOT NULL,
    content_url      TEXT         NOT NULL,
    metadata         JSON,
    created_at       TIMESTAMP    NOT NULL DEFAULT current_timestamp,
    updated_at       TIMESTAMP    NOT NULL DEFAULT current_timestamp,
    created_by       INTEGER      NOT NULL,
    updated_by       INTEGER      NOT NULL,
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE,
    FOREIGN KEY (parent_folder_id) REFERENCES folders(id)
        ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (updated_by) REFERENCES users(id)
);

COMMENT ON TABLE files IS 'Files are a kind of specialized resources that represent the actual files stored in the system. All Files must exist within a parent folder';
COMMENT ON COLUMN files.id IS 'File ID';
COMMENT ON COLUMN files.resource_id IS 'Reference to the resource table';
COMMENT ON COLUMN files.parent_folder_id IS 'Reference to the parent folder';
COMMENT ON COLUMN files.name IS 'File name; has to be unique within the parent folder';
COMMENT ON COLUMN files.content_url IS 'URL reference to the file; e.g., S3 URL';
COMMENT ON COLUMN files.metadata IS 'JSON metadata; unspecified schema for storing additional file information';
COMMENT ON COLUMN files.created_at IS 'File creation timestamp; auto-generated on creation';
COMMENT ON COLUMN files.updated_at IS 'File last update timestamp; auto-updated on every update';
COMMENT ON COLUMN files.created_by IS 'Reference to the user who created the file';
COMMENT ON COLUMN files.updated_by IS 'Reference to the user who last updated the file';



CREATE INDEX IF NOT EXISTS files_parent_folder_id_index ON files(parent_folder_id);
CREATE INDEX IF NOT EXISTS files_resource_id_index ON files(resource_id);


CREATE OR REPLACE FUNCTION validate_unique_file_name() RETURNS TRIGGER AS
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


CREATE OR REPLACE TRIGGER files_name_unique_within_parent
    BEFORE INSERT
    ON files
    FOR EACH ROW
EXECUTE FUNCTION validate_unique_file_name();



CREATE OR REPLACE FUNCTION files_update_timestamp() RETURNS TRIGGER AS
$$
BEGIN
    new.updated_at = current_timestamp;
    RETURN new;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER files_updated_at_trigger
    BEFORE UPDATE
    ON files
    FOR EACH ROW
EXECUTE FUNCTION files_update_timestamp();
END;
