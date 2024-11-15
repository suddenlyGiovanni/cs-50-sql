SET search_path TO virtual_file_system, public;

BEGIN;

DROP TABLE IF EXISTS resources CASCADE;
DROP TYPE IF EXISTS RESOURCE_TYPE CASCADE;
DO
$$
    BEGIN
        IF NOT exists(
            SELECT 1
              FROM pg_catalog.pg_type
             WHERE typname = 'RESOURCE_TYPE'
                     ) THEN CREATE TYPE RESOURCE_TYPE AS ENUM ('folder', 'file');
        END IF;
    END;
$$;


-- Initial creation of the resources table without the foreign key constraint
CREATE TABLE IF NOT EXISTS resources (
    id               SERIAL        NOT NULL PRIMARY KEY,
    type             RESOURCE_TYPE NOT NULL,
    created_at       TIMESTAMP     NOT NULL DEFAULT current_timestamp, -- auto-generated on creation
    updated_at       TIMESTAMP     NOT NULL DEFAULT current_timestamp, -- auto-updated on every update
    created_by       INTEGER       NOT NULL,
    updated_by       INTEGER       NOT NULL,
    parent_folder_id INTEGER REFERENCES resources(id),                 -- Initially no foreign key constraint
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT check_parent_folder_id_nullability CHECK ( (type = 'file' AND parent_folder_id IS NOT NULL) OR
                                                          (type = 'folder' AND
                                                           (parent_folder_id IS NULL OR parent_folder_id IS NOT NULL)) ),
    CONSTRAINT check_parent_folder_id_self_reference CHECK ( parent_folder_id IS NULL OR parent_folder_id != id )
);


COMMENT ON TABLE resources IS 'The resources table stores all the resources in the system; resources can be either folders or files';
COMMENT ON COLUMN resources.id IS 'The unique identifier for the resource';
COMMENT ON COLUMN resources.type IS 'The type of the resource; either "folder" or "file"';
COMMENT ON COLUMN resources.created_at IS 'The resource creation timestamp; auto-generated on creation';
COMMENT ON COLUMN resources.updated_at IS 'The resource last update timestamp; auto-updated on every update';
COMMENT ON COLUMN resources.created_by IS 'Reference to the user who created the resource';
COMMENT ON COLUMN resources.updated_by IS 'Reference to the user who last updated the resource';
COMMENT ON COLUMN resources.parent_folder_id IS 'Reference to the parent folder; NULL by default for top level folders; A Folder cannot be its own parent While a File must have a parent folder';

DROP INDEX IF EXISTS resources_type_index;
-- CREATE INDEX IF NOT EXISTS resources_type_index ON resources(type);


CREATE OR REPLACE FUNCTION resource_update_timestamp() RETURNS TRIGGER AS
$$
BEGIN
    IF (tg_op = 'INSERT') THEN
        new.updated_at := new.created_at;
    ELSEIF (tg_op = 'UPDATE') THEN
        new.updated_at := current_timestamp;
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION resource_update_timestamp() IS 'Function to update the updated_at timestamp on every insert or update operation on the resources table';

DROP TRIGGER IF EXISTS resources_updated_at_trigger ON resources;
CREATE TRIGGER resources_updated_at_trigger
    BEFORE INSERT OR UPDATE
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION resource_update_timestamp();

COMMIT;
