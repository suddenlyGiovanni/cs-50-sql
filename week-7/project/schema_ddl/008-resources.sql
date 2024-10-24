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
    id         SERIAL        NOT NULL PRIMARY KEY,
    type       RESOURCE_TYPE NOT NULL,
    created_at TIMESTAMP     NOT NULL DEFAULT current_timestamp,
    updated_at TIMESTAMP     NOT NULL DEFAULT current_timestamp,
    created_by INTEGER       NOT NULL,
    updated_by INTEGER       NOT NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

COMMENT ON COLUMN resources.created_at IS 'The resource creation timestamp; auto-generated on creation';
COMMENT ON COLUMN resources.updated_at IS 'The resource last update timestamp; auto-updated on every update';
COMMENT ON COLUMN resources.created_by IS 'Reference to the user who created the resource';
COMMENT ON COLUMN resources.updated_by IS 'Reference to the user who last updated the resource';

DROP INDEX IF EXISTS resources_type_index;
CREATE INDEX IF NOT EXISTS resources_type_index ON resources(type);


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



CREATE OR REPLACE FUNCTION resource_assign_owner_role_on_creation() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
DECLARE
    _user_id     INTEGER  := new.created_by;
    _resource_id INTEGER  := new.id;
    _role_id     SMALLINT := (
                             SELECT id
                               FROM roles
                              WHERE name = 'owner'
                             );
BEGIN
    -- Insert the user-role-resource mapping
    -- If it fails, the entire transaction will be rolled back
    INSERT INTO user_role_resource (resource_id, user_id, role_id) VALUES (_resource_id, _user_id, _role_id);
    RETURN new;
END;
$$;
COMMENT ON FUNCTION resource_assign_owner_role_on_creation() IS 'Automatically assigns the "owner" role to a resource for the user who created it.';



DROP TRIGGER IF EXISTS resources_assign_owner_role_trigger ON resources;
CREATE TRIGGER resources_assign_owner_role_trigger
    AFTER INSERT
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION resource_assign_owner_role_on_creation();
COMMENT ON TRIGGER resources_assign_owner_role_trigger ON resources IS 'Trigger to automatically assign the "owner" role to the user who creates a resource.';


COMMIT;


CREATE OR REPLACE FUNCTION mkdir(
    folder_name TEXT,
    username TEXT,
    role_type ROLE_TYPE DEFAULT 'owner',
    parent_folder_id INTEGER DEFAULT NULL
) RETURNS INTEGER
    LANGUAGE plpgsql AS
$$
DECLARE
    _user_id     INTEGER;
    _resource_id INTEGER;
    _folder_id   INTEGER;
    _role_id     SMALLINT;
BEGIN
    -- validate folder_name
    IF mkdir.folder_name IS NULL OR mkdir.folder_name = '' THEN
        RAISE EXCEPTION 'Folder name cannot be null or empty string';
    END IF;

    -- validate parent_folder_id
    IF mkdir.parent_folder_id IS NOT NULL THEN
        IF NOT exists(
                     SELECT 1
                       FROM folders
                      WHERE folders.id = mkdir.parent_folder_id
                     ) THEN
            RAISE EXCEPTION 'Parent folder with id % does not exist', parent_folder_id;
        END IF;
    END IF;

    -- validate unique folder name
    IF exists(
             SELECT 1 FROM folders WHERE folders.parent_folder_id = mkdir.parent_folder_id AND name = mkdir.folder_name
             ) THEN
        RAISE EXCEPTION 'Folder with name "%" already exists in the parent folder', mkdir.folder_name;
    END IF;

    -- Validate and retrieve user_id
    IF NOT exists (
                  SELECT 1
                    FROM users
                   WHERE users.username = mkdir.username
                  ) THEN
        RAISE EXCEPTION 'User "%" does not exist', mkdir.username;
    ELSE
        SELECT users.id INTO _user_id FROM users WHERE users.username = mkdir.username;
    END IF;

    -- Validate and retrieve role_id
    IF NOT exists (
                  SELECT 1
                    FROM roles
                   WHERE roles.name = mkdir.role_type
                  ) THEN
        RAISE EXCEPTION 'Role % not found', mkdir.role_type;
    ELSE
        SELECT roles.id INTO _role_id FROM roles WHERE roles.name = mkdir.role_type;
    END IF;

    -- create a new resource
       INSERT INTO resources (type, created_by, updated_by)
       VALUES ('folder', _user_id, _user_id)
    RETURNING resources.id INTO _resource_id;


    -- Create a new folder
       INSERT INTO folders (resource_id, parent_folder_id, name)
       VALUES (_resource_id, mkdir.parent_folder_id, mkdir.folder_name)
    RETURNING folders.id INTO _folder_id;

    -- Add corresponding role-based access for the new resource if different from the automatically assigned one 'owner'
    IF mkdir.role_type != 'owner' THEN
        INSERT INTO user_role_resource (resource_id, user_id, role_id) VALUES (_resource_id, _user_id, _role_id);
    END IF;


    -- TODO: needs to validate the authorisation of the user to create the folder

    RETURN _folder_id;

END;
$$;

COMMENT ON FUNCTION mkdir IS 'Create a new folder for a user with the specified role

Parameters:
- folder_name (TEXT): The name of the new folder to be created
- username (TEXT): The unique username of the user who will own the folder
- role_type (ROLE_TYPE, DEFAULT "owner"): The role type to be assigned to the folder
- parent_folder_id (INTEGER, DEFAULT NULL): The ID of the parent folder, if any
Returns:
- INTEGER: The ID of the newly created folder
';



CREATE OR REPLACE FUNCTION chmod(
    resource_id INTEGER,
    username TEXT,
    role_type ROLE_TYPE
) RETURNS VOID
    LANGUAGE plpgsql AS
$$
DECLARE
    _role_id SMALLINT := (
    SELECT roles.id
      FROM roles
     WHERE roles.name = chmod.role_type
                         );
    _user_id INTEGER;
BEGIN

    -- Validate and retrieve user_id
    IF NOT exists (
                  SELECT 1
                    FROM users
                   WHERE users.username = chmod.username
                  ) THEN
        RAISE EXCEPTION 'User "%" does not exist', chmod.username;
    ELSE
        SELECT users.id INTO _user_id FROM users WHERE users.username = chmod.username;
    END IF;

    -- Validate role_id
    IF _role_id IS NULL THEN RAISE EXCEPTION 'Role % does not exist', chmod.role_type; END IF;

    -- Validate resource_id
    IF NOT exists (
                  SELECT 1
                    FROM resources
                   WHERE resources.id = chmod.resource_id
                  ) THEN
        RAISE EXCEPTION 'Resource with id % does not exist', chmod.resource_id;
    END IF;


    -- Insert or update the user-role-resource relationship
    INSERT INTO user_role_resource (resource_id, user_id, role_id)
    VALUES (chmod.resource_id, _user_id, _role_id)
        ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;

    RAISE NOTICE 'Role "%" assigned to user "%" for resource id "%"', chmod.role_type, chmod.username, chmod.resource_id;

END;
$$;
COMMENT ON FUNCTION chmod IS 'Change the mode of a file or folder';
