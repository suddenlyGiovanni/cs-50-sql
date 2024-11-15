SET search_path TO virtual_file_system, public;

BEGIN;

DROP TABLE IF EXISTS files CASCADE;
CREATE TABLE IF NOT EXISTS files (
    id           SERIAL PRIMARY KEY,
    resource_id  INTEGER      NOT NULL UNIQUE,
    name         VARCHAR(255) NOT NULL CHECK ( trim(name) != '' ),
    mime_type    VARCHAR(255) NOT NULL CHECK ( trim(mime_type) != '' ),
    size         BIGINT       NOT NULL DEFAULT 0,
    storage_path TEXT         NOT NULL CHECK ( trim(storage_path) != '' ),
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE
);

COMMENT ON TABLE files IS 'Files are a kind of specialized resources that represent the actual files stored in the system. All Files must exist within a parent folder';
COMMENT ON COLUMN files.id IS 'File ID';
COMMENT ON COLUMN files.resource_id IS 'Reference to the resource table';
COMMENT ON COLUMN files.name IS 'File name; has to be unique within the parent folder';
COMMENT ON COLUMN files.mime_type IS 'File MIME type; e.g. application/pdf, image/jpeg, etc.';
COMMENT ON COLUMN files.size IS 'File size in bytes';
COMMENT ON COLUMN files.storage_path IS 'URL reference to the file; e.g., S3 URL';

DROP INDEX IF EXISTS files_resource_id_index;
-- CREATE INDEX IF NOT EXISTS files_resource_id_index ON files(resource_id);
-- COMMENT ON INDEX files_resource_id_index IS 'Index to enable fast lookups for the resource_id column';

DROP INDEX IF EXISTS files_name_unique_within_parent_folder_index;
-- CREATE UNIQUE INDEX files_name_unique_within_parent_folder_index ON files(parent_folder_id, name);
-- COMMENT ON INDEX files_name_unique_within_parent_folder_index IS 'Unique index to enforce the unique files name within the parent folder; Enables fast lookups for the files name within the parent folder';


CREATE OR REPLACE TRIGGER files_validate_name_uniqueness_trigger
    BEFORE INSERT OR UPDATE
    ON files
    FOR EACH ROW
EXECUTE FUNCTION files_validate_name_uniqueness();

COMMIT;
