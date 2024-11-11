CREATE OR REPLACE FUNCTION chmod(
    resource INTEGER,
    username TEXT,
    role_type ROLE_TYPE
) RETURNS SETOF public.USER_ROLE_RESOURCE AS
$$
DECLARE
    _role_id SMALLINT := (
                             SELECT roles.id
                               FROM roles
                              WHERE roles.name = chmod.role_type
                         );
    _user_id INTEGER;

BEGIN

    /*
     * Argument validation:
     */

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
    IF _role_id IS NULL THEN
        RAISE EXCEPTION 'Role % does not exist', chmod.role_type;
    END IF;

    -- Validate resource_id
    IF NOT exists (
        SELECT 1
          FROM resources
         WHERE resources.id = chmod.resource
                  ) THEN
        RAISE EXCEPTION 'Resource with id % does not exist', chmod.resource;
    END IF;

    /*
     * Business logic:
     * - Insert or update the user-role-resource relationship
     * - Return the modified user_role_resource record
     */

    -- Insert or update the user-role-resource relationship
    INSERT
      INTO user_role_resource (resource_id, user_id, role_id)
    VALUES (chmod.resource, _user_id, _role_id)
        ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;

    RAISE NOTICE 'Role "%" assigned to user "%" for resource id "%"', chmod.role_type, chmod.username, chmod.resource;

    RETURN QUERY SELECT * FROM user_role_resource WHERE resource_id = chmod.resource AND user_id = _user_id;
END;


$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION chmod IS 'Change user role attached to a resource.

Parameters:
- resource (INTEGER): The ID of the resource (file or folder) to which the role should be assigned.
- username (TEXT): The unique username of the user to whom the role should be assigned.
- role_type (ROLE_TYPE): The role type to be assigned to the user.

Returns:
- the modified user_role_resource record';
