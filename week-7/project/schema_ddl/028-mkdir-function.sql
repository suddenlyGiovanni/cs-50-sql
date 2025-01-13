SET search_path TO virtual_file_system, public;

BEGIN;

CREATE OR REPLACE FUNCTION mkdir(
    _folder_name TEXT,
    _user_id INTEGER,
    _role_type ROLE DEFAULT 'owner'::ROLE,
    _parent_folder_id INTEGER DEFAULT NULL
) RETURNS INTEGER AS
$$
DECLARE
    _resource_id INTEGER;
    _folder_id   INTEGER;
    _role_id     SMALLINT;
BEGIN
    /*
     * argument validation:
    */

    -- validate folder_name
    IF mkdir._folder_name IS NULL OR mkdir._folder_name = '' THEN
        RAISE EXCEPTION 'Folder name cannot be null or empty string';
    END IF;

    -- validate parent_folder_id
    IF mkdir._parent_folder_id IS NOT NULL THEN
        IF NOT exists(
            SELECT 1 --
              FROM resources r --
             WHERE r.id = mkdir._parent_folder_id AND r.type = 'folder'::RESOURCE
                     ) THEN
            RAISE EXCEPTION 'Parent folder with id "%" does not exist', _parent_folder_id;
        END IF;
    END IF;

    -- validate unique folder name
    IF exists(
        SELECT 1
          FROM resources   r
              JOIN folders f ON f.resource_id = r.id
         WHERE mkdir._parent_folder_id = r.parent_folder_id
           AND r.type = 'folder'::RESOURCE
           AND mkdir._folder_name = f.name
             ) THEN
        RAISE EXCEPTION 'Folder with name "%" already exists in the parent folder', mkdir._folder_name;
    END IF;

    -- Validate and retrieve user_id
    IF NOT exists (
        SELECT 1
          FROM users u
         WHERE mkdir._user_id = u.id
                  ) THEN
        RAISE EXCEPTION 'User "%" does not exist', mkdir._user_id;
    END IF;

    -- Validate and retrieve role_id
    IF NOT exists (
        SELECT 1
          FROM roles r
         WHERE mkdir._role_type = r.name
                  ) THEN
        RAISE EXCEPTION 'Role % not found', mkdir._role_type;
    ELSE
        SELECT roles.id INTO _role_id FROM roles WHERE mkdir._role_type = roles.name;
    END IF;

    -- validate permission to create a folder in the parent folder
    IF NOT exists(
        SELECT 1
          FROM user_role_resource_access_view urrav
         WHERE urrav.user_id = _user_id
           AND urrav.resource_id = mkdir._parent_folder_id
           AND urrav.write IS TRUE
                 ) THEN
        RAISE EXCEPTION 'User "%" does not have "write" permission on the parent folder "%".', mkdir._user_id , mkdir._parent_folder_id;
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
       VALUES ('folder', _user_id, _user_id, mkdir._parent_folder_id)
    RETURNING resources.id INTO _resource_id;


    -- Create a new `folder` resource
       INSERT
         INTO folders (resource_id, name) --
       VALUES (_resource_id, mkdir._folder_name) --
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


COMMENT ON FUNCTION mkdir IS 'Create a new folder for a user with the specified role

Parameters:
- _folder_name (TEXT): The name of the new folder to be created
- _user_id (TEXT): The id of the user who will own the folder
- _role_type (ROLE, DEFAULT "owner"): The role type to be assigned to the folder
- _parent_folder_id (INTEGER, DEFAULT NULL): The ID of the parent folder, if any
Returns:
- INTEGER: The ID of the newly created folder resource
';
COMMIT;
