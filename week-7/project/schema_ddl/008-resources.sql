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
    parent_folder_id INTEGER,                                          -- Initially no foreign key constraint
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


CREATE OR REPLACE FUNCTION validate_parent_folder_id() RETURNS TRIGGER AS
$$
BEGIN
    /*
    * A resource can be either a `folder` or a `file` type
    *
    * a valid `file` resource must have the parent_folder_ id:
    * - that must not be null
    * - must exist in the folder table
    *
    * a valid `folder` resource can either be a top level folder or a subfolder:
    * - a top-level folder must have a null parent_folder_id
    * - a subfolder must have a valid parent_folder_id that exists in the folder table
    */

    IF new.type = 'file' THEN
        IF new.parent_folder_id IS NULL THEN RAISE EXCEPTION 'A file resource must have a parent folder'; END IF;
        IF NOT exists(
                     SELECT 1
                       FROM folders
                      WHERE folders.id = new.parent_folder_id
                     ) THEN
            RAISE EXCEPTION 'Parent folder with id "%" does not exist', new.parent_folder_id;
        END IF;


    ELSIF new.type = 'folder' THEN
        IF new.parent_folder_id IS NOT NULL THEN
            IF NOT exists(
                         SELECT 1
                           FROM folders
                          WHERE folders.id = new.parent_folder_id
                         ) THEN
                RAISE EXCEPTION 'Parent folder with id "%" does not exist', new.parent_folder_id;
            END IF;
        END IF;
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION validate_parent_folder_id IS 'Ensure that the parent folder exists for the folder being inserted or updated';

CREATE OR REPLACE TRIGGER validate_parent_folder_id_trigger
    BEFORE INSERT OR UPDATE OF parent_folder_id
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION validate_parent_folder_id();


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


-- Now adding the foreign key constraint to the resources table
ALTER TABLE resources
    ADD CONSTRAINT fk_parent_folder FOREIGN KEY (parent_folder_id) REFERENCES folders(id)
        ON DELETE CASCADE;



-- CREATE OR REPLACE FUNCTION prevent_folders_circular_dependency() RETURNS TRIGGER
--     LANGUAGE plpgsql AS
-- $$
-- BEGIN
--     -- Recursively check the parent chain to ensure there's no circular dependency
--     IF exists (
--               WITH RECURSIVE folder_ancestors AS (
--                                                  SELECT parent_folder_id
--                                                    FROM folders
--                                                   WHERE folders.id = new.parent_folder_id
--                                                   UNION ALL
--                                                  SELECT folders.parent_folder_id
--                                                    FROM folders
--                                                        INNER JOIN folder_ancestors ON folders.id = folder_ancestors.parent_folder_id
--                                                  )
--             SELECT 1
--               FROM folders
--              WHERE folders.parent_folder_id = new.id
--               ) THEN
--         RAISE EXCEPTION 'Circular dependency detected: folder id "%" cannot be its own ancestor', new.id;
--     END IF;
--     RETURN new;
-- END;
-- $$;
-- COMMENT ON FUNCTION prevent_folders_circular_dependency IS 'Prevent circular dependency in the folders table';


-- CREATE OR REPLACE TRIGGER prevent_circular_dependency_trigger
--     BEFORE INSERT OR UPDATE OF parent_folder_id
--     ON folders
--     FOR EACH ROW
-- EXECUTE FUNCTION prevent_folders_circular_dependency();


-- CREATE OR REPLACE FUNCTION auth_create_trigger() RETURNS TRIGGER AS
-- $$
-- DECLARE
--     _user_id           INTEGER;
--     _current_folder_id INTEGER := new.parent_folder_id;
-- BEGIN
--     /*
-- 	 * Algorithm:
-- 	 * 1. get the user_id from the reference to the resources table
-- 	 * 2. check for direct authorization to write permission on the parent_folder_id; if found allow the operation
-- 	 * 3. traverse the parent chain recursively
-- 	 *    - for each ancestor folder, check if the user has the required access rights
-- 	 *    - if the user has the required access rights, allow the operation
-- 	 * 4. stop the traversal when the parent_folder_id is NULL, indicating the top-level folder
-- 	 * 5. if the traversal reaches the top-level folder and the user does not have the required access rights, deny the operation by raising an exception
--      */
--
--     -- 1. get the user_id from the reference to the resource table
--     SELECT created_by INTO _user_id FROM resources WHERE id = new.resource_id;
--
--     -- if parent_folder_id is NULL, indicating it is a top-level folder, skip the authorization check
--     IF _current_folder_id IS NULL THEN RETURN new; END IF;
--
--     -- 2. check for direct authorization to write permission on the parent_folder_id; if found allow the operation
--
--     WHILE _current_folder_id IS NOT NULL
--         LOOP
--             IF exists(
--                      SELECT 1
--                        FROM user_role_resource_access_view AS urrav
--                       WHERE urrav.resource_id = _current_folder_id
--                         AND urrav.user_id = _user_id
--                         AND urrav.write = TRUE
--                      ) THEN
--                 -- if a valid write permission is found, allow the operation
--                 RETURN new;
--             ELSE
--                 -- 3. traverse to the parent folder
--                 SELECT folders.parent_folder_id
--                   INTO _current_folder_id
--                   FROM folders
--                  WHERE folders.id = _current_folder_id;
--             END IF;
--         END LOOP;
--
--     -- 5. if the traversal reaches the top-level folder and the user does not have the required access rights, deny the operation by raising an exception
--     RAISE EXCEPTION 'User "%" does not have write permissions for this folder or any parent folders', _user_id;
--
-- END;
-- $$ LANGUAGE plpgsql;
-- COMMENT ON FUNCTION auth_create_trigger IS 'Trigger function to enforce authorization rules on the folders table';


-- CREATE OR REPLACE TRIGGER auth_folder_create_trigger
--     BEFORE INSERT
--     ON folders
--     FOR EACH ROW
-- EXECUTE FUNCTION auth_create_trigger();


DROP TABLE IF EXISTS files CASCADE;
CREATE TABLE IF NOT EXISTS files (
    id           SERIAL PRIMARY KEY,
    resource_id  INTEGER      NOT NULL UNIQUE,
    name         VARCHAR(255) NOT NULL,
    mime_type    VARCHAR(255) NOT NULL,
    size         BIGINT       NOT NULL DEFAULT 0,
    storage_path TEXT         NOT NULL,
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

-- CREATE OR REPLACE FUNCTION validate_file_parent_folder_existence() RETURNS TRIGGER AS
-- $$
-- BEGIN
--     -- check if the parent folder exists (if not NULL)
--     IF NOT exists(
--                  SELECT 1
--                    FROM folders
--                   WHERE folders.id = new.parent_folder_id
--                  ) THEN
--         RAISE EXCEPTION 'The specified parent_folder_id "%" does not exist', new.parent_folder_id;
--     END IF;
--     RETURN new;
-- END;
-- $$ LANGUAGE plpgsql;
-- COMMENT ON FUNCTION validate_file_parent_folder_existence IS 'Ensure that the parent folder exists for the folder being inserted or updated';

-- CREATE OR REPLACE TRIGGER validate_file_parent_folder_existence_trigger
--     BEFORE INSERT OR UPDATE OF parent_folder_id
--     ON files
--     FOR EACH ROW
-- EXECUTE FUNCTION validate_file_parent_folder_existence();


COMMIT;
