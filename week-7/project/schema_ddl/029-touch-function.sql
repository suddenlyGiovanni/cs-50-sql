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
        RAISE EXCEPTION 'File with name "%" already exists in the parent folder', touch._name;
    END IF;

    -- Validate user_id
    IF NOT exists (
        SELECT 1
          FROM users
         WHERE touch._user_id = users.id
                  ) THEN
        RAISE EXCEPTION 'User "%" does not exist', touch._user_id;
    END IF;


    /*
     * Core logic:
     * - create a new resource
     * - create a new file
     * - assign the file to the user
     */

    -- Create a new resource
       INSERT
         INTO resources (created_by, updated_by, type, parent_folder_id)
       VALUES (_user_id, _user_id, 'file', _parent_folder_id)
    RETURNING resources.id INTO _resource_id;

    -- Create a new file
       INSERT
         INTO files (resource_id, name, mime_type, size, storage_path)
       VALUES (_resource_id, _name, _mime_type, _size, _storage_path)
    RETURNING files.id INTO _file_id;


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
