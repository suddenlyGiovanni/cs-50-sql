CREATE OR REPLACE FUNCTION chmod(
    _resource_id INTEGER,
    _user_id INTEGER,
    _role_type ROLE_TYPE
) RETURNS SETOF public.USER_ROLE_RESOURCE AS
$$
DECLARE
    _role_id SMALLINT := (
        SELECT r.id
          FROM virtual_file_system.public.roles r
         WHERE r.name = chmod._role_type
                         );

BEGIN

    /*
     * Argument validation:
     */

    -- Validate user_id
    IF NOT exists (
        SELECT 1 FROM virtual_file_system.public.users u WHERE u.id = chmod._user_id
                  ) THEN
        RAISE EXCEPTION 'User "%" does not exist', chmod._user_id;
    END IF;

    -- Validate role_id
    IF _role_id IS NULL THEN
        RAISE EXCEPTION 'Role "%" does not exist', chmod._role_type;
    END IF;

    -- Validate resource_id
    IF NOT exists (
        SELECT 1 FROM virtual_file_system.public.resources r WHERE r.id = chmod._resource_id
                  ) THEN
        RAISE EXCEPTION 'Resource with id % does not exist', chmod._resource_id;
    END IF;

    /*
     * Business logic:
     * - Insert or update the user-role-resource relationship
     * - Return the modified user_role_resource record
     */

    -- Insert or update the user-role-resource relationship
    INSERT
      INTO virtual_file_system.public.user_role_resource (resource_id, user_id, role_id)
    VALUES (chmod._resource_id, chmod._user_id, _role_id)
        ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;

    RAISE NOTICE 'Role "%" assigned to user "%" for resource id "%"', chmod._role_type, chmod._user_id, chmod._resource_id;

    RETURN QUERY SELECT *
                   FROM virtual_file_system.public.user_role_resource urr
                  WHERE urr.resource_id = chmod._resource_id
                    AND urr.user_id = chmod._user_id;
END;


$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION chmod IS 'Change user role attached to a resource.

Parameters:
- _resource_id (INTEGER): The ID of the resource (file or folder) to which the role should be assigned.
- _user_id (INTEGER): The ID of the user to which to assign the resource-role.
- _role_type (ROLE_TYPE): The role type to be assigned to the user.

Returns:
- the modified user_role_resource record';
