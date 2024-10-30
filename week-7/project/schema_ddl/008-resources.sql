BEGIN;

DROP TABLE IF EXISTS resources CASCADE;
DROP TYPE IF EXISTS RESOURCE_TYPE CASCADE;
DO
$$
    BEGIN
        IF NOT exists(
                     SELECT 1
                       FROM pg_type
                      WHERE typname = 'RESOURCE_TYPE'
                     ) THEN CREATE TYPE RESOURCE_TYPE AS ENUM ('folder', 'file');
        END IF;
    END;
$$;



CREATE TABLE IF NOT EXISTS resources (
    id               SERIAL        NOT NULL PRIMARY KEY,
    type             RESOURCE_TYPE NOT NULL,
    created_at       TIMESTAMP     NOT NULL DEFAULT current_timestamp,
    updated_at       TIMESTAMP     NOT NULL DEFAULT current_timestamp,
    created_by       INTEGER       NOT NULL,
    updated_by       INTEGER       NOT NULL,
    parent_folder_id INTEGER,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (parent_folder_id) REFERENCES folders(id)
        ON DELETE CASCADE,
    CONSTRAINT check_parent_folder_id_nullability CHECK ( (type = 'file' AND parent_folder_id IS NOT NULL) OR
                                                          (type = 'folder' AND
                                                           (parent_folder_id IS NULL OR parent_folder_id IS NOT NULL)) ),
    CONSTRAINT check_parent_folder_id_self_reference CHECK ( parent_folder_id IS NULL OR parent_folder_id != parent_folder_id )
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
    new.updated_at = current_timestamp;
    RETURN new;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS resources_updated_at_trigger ON resources;
CREATE TRIGGER resources_updated_at_trigger
    BEFORE UPDATE
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION resource_update_timestamp();

--
-- CREATE OR REPLACE FUNCTION resource_assign_owner_role_on_creation() RETURNS TRIGGER
--     LANGUAGE plpgsql AS
-- $$
-- DECLARE
--     _user_id     INTEGER  := new.created_by;
--     _resource_id INTEGER  := new.id;
--     _role_id     SMALLINT := (
--                              SELECT id
--                                FROM roles
--                               WHERE name = 'owner'
--                              );
-- BEGIN
--     -- Insert the user-role-resource mapping
--     -- If it fails, the entire transaction will be rolled back
--     INSERT INTO user_role_resource (resource_id, user_id, role_id) VALUES (_resource_id, _user_id, _role_id);
--     RETURN new;
-- END;
-- $$;
-- COMMENT ON FUNCTION resource_assign_owner_role_on_creation() IS 'Automatically assigns the "owner" role to a resource for the user who created it.';
--
--
--
-- DROP TRIGGER IF EXISTS resources_assign_owner_role_trigger ON resources;
-- CREATE TRIGGER resources_assign_owner_role_trigger
--     AFTER INSERT
--     ON resources
--     FOR EACH ROW
-- EXECUTE FUNCTION resource_assign_owner_role_on_creation();
-- COMMENT ON TRIGGER resources_assign_owner_role_trigger ON resources IS 'Trigger to automatically assign the "owner" role to the user who creates a resource.';


COMMIT;
