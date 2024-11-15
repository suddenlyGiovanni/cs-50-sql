SET search_path TO virtual_file_system, public;

BEGIN;

DROP TABLE IF EXISTS resources CASCADE;

-- Initial creation of the resources table without the foreign key constraint
CREATE TABLE IF NOT EXISTS resources (
    id               SERIAL    NOT NULL PRIMARY KEY,
    type             RESOURCE  NOT NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT current_timestamp, -- auto-generated on creation
    updated_at       TIMESTAMP NOT NULL DEFAULT current_timestamp, -- auto-updated on every update
    created_by       INTEGER   NOT NULL,
    updated_by       INTEGER   NOT NULL,
    parent_folder_id INTEGER REFERENCES resources(id),             -- Initially no foreign key constraint
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


DROP TRIGGER IF EXISTS resources_updated_at_trigger ON resources;
CREATE TRIGGER resources_updated_at_trigger
    BEFORE INSERT OR UPDATE
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION resource_update_timestamp();

DROP TRIGGER IF EXISTS resources_validate_parent_folder_id_trigger ON resources;
CREATE OR REPLACE TRIGGER resources_validate_parent_folder_id_trigger
    BEFORE INSERT OR UPDATE OF parent_folder_id
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION resources_validate_parent_folder_id();

DROP TRIGGER IF EXISTS resources_validate_folders_circular_dependency_trigger ON resources;
CREATE OR REPLACE TRIGGER resources_validate_folders_circular_dependency_trigger
    BEFORE INSERT OR UPDATE OF parent_folder_id
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION resources_validate_folders_circular_dependency();


DROP TRIGGER IF EXISTS resources_validate_authorization_trigger ON resources;
CREATE OR REPLACE TRIGGER resources_validate_authorization_trigger
    BEFORE INSERT OR UPDATE
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION auth_create_trigger();


DROP TRIGGER IF EXISTS resources_ownership_assignment_trigger ON resources;
DROP TRIGGER IF EXISTS resources_ownership_assignment_trigger ON resources;
CREATE TRIGGER resources_ownership_assignment_trigger
    AFTER INSERT
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION resources_ownership_assignment_on_insert();
COMMENT ON TRIGGER resources_ownership_assignment_trigger ON resources IS 'Trigger to automatically assign the "owner" role to the user who creates a resource.';

COMMIT;
