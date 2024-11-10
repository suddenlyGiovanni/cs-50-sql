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
