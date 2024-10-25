CREATE OR REPLACE FUNCTION mkdir(
    folder_name TEXT,
    username TEXT,
    role_type ROLE_TYPE DEFAULT 'owner',
    parent_folder_id INTEGER DEFAULT NULL
) RETURNS INTEGER AS
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
$$ LANGUAGE plpgsql;


COMMENT ON FUNCTION mkdir IS 'Create a new folder for a user with the specified role

Parameters:
- folder_name (TEXT): The name of the new folder to be created
- username (TEXT): The unique username of the user who will own the folder
- role_type (ROLE_TYPE, DEFAULT "owner"): The role type to be assigned to the folder
- parent_folder_id (INTEGER, DEFAULT NULL): The ID of the parent folder, if any
Returns:
- INTEGER: The ID of the newly created folder
';
