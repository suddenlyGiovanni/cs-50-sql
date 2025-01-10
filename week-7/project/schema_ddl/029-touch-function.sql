SET search_path TO virtual_file_system, public;

BEGIN;
CREATE OR REPLACE FUNCTION touch(
    _user_id INTEGER,
    _name VARCHAR(255),
    _mime_type VARCHAR(255),
    _parent_folder_id INTEGER,
    _storage_path TEXT,
    _size BIGINT = 0
) RETURNS INTEGER AS
$$
DECLARE
    _resource_id INTEGER;
    _file_id     INTEGER;
BEGIN
    /**
	 * argument validation:
	 */

    -- Validate user_id
    IF NOT exists (
        SELECT 1
          FROM users
         WHERE touch._user_id = users.id
                  ) THEN
        RAISE EXCEPTION 'User "%" does not exist', touch._user_id;
    END IF;

    -- validate parent_folder_id
    IF NOT exists(
        SELECT 1 --
          FROM resources r --
         WHERE r.id = touch._parent_folder_id AND r.type = 'folder'
                 ) THEN
        RAISE EXCEPTION 'Parent folder with id "%" does not exist', _parent_folder_id;
    END IF;


    -- validate unique file name
    IF exists(
        SELECT 1
          FROM resources
              JOIN files ON files.resource_id = resources.id
         WHERE touch._parent_folder_id = resources.parent_folder_id
           AND resources.type = 'file'
           AND touch._name = files.name
             ) THEN
        RAISE EXCEPTION 'File with name "%" already exists in the parent folder "%"', touch._name, touch._parent_folder_id;
    END IF;

    -- validate permission to create a file in the parent folder
    -- translate into checking that the _user_id has write permission on the _parent_folder_id
    IF NOT exists(
        SELECT 1
          FROM user_role_resource_access_view urrav
         WHERE urrav.user_id = _user_id
           AND urrav.resource_id = _parent_folder_id
           AND urrav.write IS TRUE
                 ) THEN
        RAISE EXCEPTION 'User "%" does not have write permission on the parent folder "%"', touch._user_id , touch._parent_folder_id;
    END IF;


    /*
     * Core logic:
     * - create a new resource
     * - create a new file
     * - assign the file to the user
     */

    -- Create a new resource
       INSERT
         INTO resources (type, created_by, updated_by, parent_folder_id)
       VALUES ('file'::RESOURCE, _user_id, _user_id, _parent_folder_id)
    RETURNING resources.id INTO _resource_id;

    -- Create a new file
       INSERT
         INTO files (resource_id, name, mime_type, size, storage_path)
       VALUES (_resource_id, _name, _mime_type, _size, _storage_path)
    RETURNING files.id INTO _file_id;

    -- Apply to the file resource the same access role as the parent folder
    INSERT
      INTO user_role_resource (resource_id, user_id, role_id)
    VALUES (_resource_id, _user_id, (
        SELECT urr2.role_id --
          FROM user_role_resource urr2 --
         WHERE urr2.resource_id = _parent_folder_id --
           AND urr2.user_id = _user_id
                                    ))
        ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;

    RETURN _file_id;

END;
$$ LANGUAGE plpgsql;


COMMENT ON FUNCTION touch IS 'Create a new file in the parent folder
Parameters:
- _user_id: the id of the user creating the file
- _name: the name of the file
- _mime_type: the mime type of the file
- _parent_folder_id: the id of the parent folder
- _storage_path: the path to the file in the storage system
- _size: the size of the file in bytes
Returns:
- the id of the newly created file';
COMMIT;
