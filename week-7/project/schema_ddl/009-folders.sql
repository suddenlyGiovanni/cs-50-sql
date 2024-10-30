BEGIN;

DROP TABLE IF EXISTS folders CASCADE;

CREATE TABLE IF NOT EXISTS folders (
    id          SERIAL PRIMARY KEY,
    resource_id INTEGER      NOT NULL UNIQUE,
--     parent_folder_id INTEGER DEFAULT NULL CHECK ( parent_folder_id != id ) REFERENCES folders
--         ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    FOREIGN KEY (resource_id) REFERENCES resources(id)
        ON DELETE CASCADE
);

COMMENT ON TABLE folders IS 'Folders are a kind of specialized resources that represent the hierarchical folders structure. The parent-child relationship is defined by a self-referencing foreign key for the subfolders';
COMMENT ON COLUMN folders.id IS 'Folder ID';
COMMENT ON COLUMN folders.resource_id IS 'Reference to the resource table';
COMMENT ON COLUMN folders.name IS 'Folder name; has to be unique within the parent folder';
-- COMMENT ON COLUMN folders.parent_folder_id IS 'Reference to the parent folder; NULL by default for top level folders; A Folder cannot be its own parent';


DROP INDEX IF EXISTS folders_resource_id_index;
-- CREATE INDEX IF NOT EXISTS folders_resource_id_index ON folders(resource_id);
-- COMMENT ON INDEX folders_resource_id_index IS 'Index to enable fast lookups for the resource_id column';

DROP INDEX IF EXISTS folders_parent_folder_name_unique_idx;
-- CREATE UNIQUE INDEX folders_parent_folder_name_unique_idx ON folders(parent_folder_id, name);
-- COMMENT ON INDEX folders_parent_folder_name_unique_idx IS 'Unique index to enforce the unique folder name within the parent folder; Enables fast lookups for the folder name within the parent folder';


-- CREATE OR REPLACE FUNCTION validate_parent_folder_existence() RETURNS TRIGGER AS
-- $$
-- BEGIN
--     -- check if the parent is NULL, indicating it is a top-level folder; skip the check as it is valid
--     IF new.parent_folder_id IS NOT NULL THEN
--         -- validate that the specified parent folder exists
--         IF NOT exists(
--                      SELECT 1
--                        FROM folders
--                       WHERE folders.id = new.parent_folder_id
--                      ) THEN
--             RAISE EXCEPTION 'Parent folder with id "%" does not exist', new.parent_folder_id;
--         END IF;
--     END IF;
--     RETURN new;
-- END;
-- $$ LANGUAGE plpgsql;
-- COMMENT ON FUNCTION validate_parent_folder_existence IS 'Ensure that the parent folder exists for the folder being inserted or updated';

-- CREATE OR REPLACE TRIGGER validate_parent_folder_existence_trigger
--     BEFORE INSERT OR UPDATE OF parent_folder_id
--     ON folders
--     FOR EACH ROW
-- EXECUTE FUNCTION validate_parent_folder_existence();


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


COMMIT;
