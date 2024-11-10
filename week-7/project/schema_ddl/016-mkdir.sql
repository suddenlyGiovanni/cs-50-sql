CREATE OR REPLACE FUNCTION virtual_file_system.public.mkdir(
    folder_name TEXT,
    username TEXT,
    role_type ROLE_TYPE DEFAULT 'owner'::ROLE_TYPE,
    parent_folder_id INTEGER DEFAULT NULL
) RETURNS INTEGER AS
$$
DECLARE
    _user_id     INTEGER;
    _resource_id INTEGER;
    _folder_id   INTEGER;
    _role_id     SMALLINT;
BEGIN
    /*
     * argument validation:
    */

    -- validate folder_name
    IF mkdir.folder_name IS NULL OR mkdir.folder_name = '' THEN
        RAISE EXCEPTION 'Folder name cannot be null or empty string';
    END IF;

    -- validate parent_folder_id
    IF mkdir.parent_folder_id IS NOT NULL THEN
        IF NOT exists(
            SELECT 1 --
              FROM resources r --
             WHERE r.id = mkdir.parent_folder_id AND r.type = 'folder'
                     ) THEN
            RAISE EXCEPTION 'Parent folder with id % does not exist', parent_folder_id;
        END IF;
    END IF;

    -- validate unique folder name
    IF exists(
        SELECT 1
          FROM resources
              JOIN folders ON folders.resource_id = resources.id
         WHERE mkdir.parent_folder_id = resources.parent_folder_id
           AND resources.type = 'folder'
           AND mkdir.folder_name = folders.name
             ) THEN
        RAISE EXCEPTION 'Folder with name "%" already exists in the parent folder', mkdir.folder_name;
    END IF;

    -- Validate and retrieve user_id
    IF NOT exists (
        SELECT 1
          FROM users
         WHERE mkdir.username = users.username
                  ) THEN
        RAISE EXCEPTION 'User "%" does not exist', mkdir.username;
    ELSE
        SELECT users.id INTO _user_id FROM users WHERE mkdir.username = users.username;
    END IF;

    -- Validate and retrieve role_id
    IF NOT exists (
        SELECT 1
          FROM roles
         WHERE mkdir.role_type = roles.name
                  ) THEN
        RAISE EXCEPTION 'Role % not found', mkdir.role_type;
    ELSE
        SELECT roles.id INTO _role_id FROM roles WHERE mkdir.role_type = roles.name;
    END IF;

    /*
     * Core logic:
     * - create a new resource
     * - create a new folder
     * - assign the folder to the user
     */

    -- Create a new resource
       INSERT
         INTO resources (type, created_by, updated_by, parent_folder_id)
       VALUES ('folder', _user_id, _user_id, mkdir.parent_folder_id)
    RETURNING resources.id INTO _resource_id;

    -- TODO: needs to validate the authorisation of the user to create the folder

    -- Create a new `folder` resource
       INSERT
         INTO folders (resource_id, name) --
       VALUES (_resource_id, mkdir.folder_name) --
    RETURNING folders.id INTO _folder_id;


    -- Add corresponding role-based access for the new resource if different from the automatically assigned one 'owner'
    --     IF mkdir.role_type != 'owner' THEN
    --     END IF;
    INSERT
      INTO user_role_resource (resource_id, user_id, role_id)
    VALUES (_resource_id, _user_id, _role_id)
        ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;

    RETURN _resource_id;

END ;
$$ LANGUAGE plpgsql;


COMMENT ON FUNCTION virtual_file_system.public.mkdir IS 'Create a new folder for a user with the specified role

Parameters:
- folder_name (TEXT): The name of the new folder to be created
- username (TEXT): The unique username of the user who will own the folder
- role_type (ROLE_TYPE, DEFAULT "owner"): The role type to be assigned to the folder
- parent_folder_id (INTEGER, DEFAULT NULL): The ID of the parent folder, if any
Returns:
- INTEGER: The ID of the newly created folder
';
