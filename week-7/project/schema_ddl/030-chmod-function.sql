SET search_path TO virtual_file_system, public;

BEGIN;

CREATE OR REPLACE FUNCTION chmod(
    _admin_user_id INTEGER,
    _resource_id INTEGER,
    _user_id INTEGER,
    _role_type ROLE
) RETURNS SETOF USER_ROLE_RESOURCE AS
$$
DECLARE
    _role_id              SMALLINT := (
                                          SELECT r.id
                                            FROM roles r
                                           WHERE r.name = chmod._role_type
                                      );
    _admin_role_id        SMALLINT := (
                                          SELECT r.id
                                            FROM roles r
                                           WHERE r.name = 'admin'::ROLE
                                      );
    _has_admin_permission BOOLEAN  := FALSE;

BEGIN

    /*
     * Argument validation:
     */

    -- validate admin_user_id
    IF NOT exists(
        SELECT 1
          FROM users u
         WHERE u.id = chmod._admin_user_id
                 ) THEN
        RAISE EXCEPTION 'Admin user "%" does not exists.', chmod._admin_user_id;
    END IF;

    -- Validate user_id
    IF NOT exists (
        SELECT 1
          FROM users u
         WHERE u.id = chmod._user_id
                  ) THEN
        RAISE EXCEPTION 'User "%" does not exist.', chmod._user_id;
    END IF;

    -- Validate role_id
    IF _role_id IS NULL THEN
        RAISE EXCEPTION 'Role "%" does not exist', chmod._role_type;
    END IF;

    -- validate resource_id is not NULL
    IF chmod._resource_id IS NULL THEN
        RAISE EXCEPTION 'Resource id cannot be NULL.';
    END IF;

    -- Validate resource_id
    IF NOT exists (
        SELECT 1
          FROM resources r
         WHERE r.id = chmod._resource_id
                  ) THEN
        RAISE EXCEPTION 'Resource with id "%" does not exist.', chmod._resource_id;
    END IF;


    /*
     * Admin validation:
     * Validate _admin_user_id is admin on the resource or higher up the folder hierarchy.
     */

      WITH RECURSIVE resource_hierarchy AS (
          -- Anchor query: Start with the specified resource
          SELECT r.id
               , r.parent_folder_id
            FROM resources r
           WHERE r.id = chmod._resource_id

           UNION ALL

-- Recursive query: Find parent resources
          SELECT r_parent.id
               , r_parent.parent_folder_id
            FROM resources                    r_parent
                INNER JOIN resource_hierarchy rh ON r_parent.id = rh.parent_folder_id
                                           )
    SELECT exists(
        SELECT 1
          FROM resource_hierarchy           rh
              INNER JOIN user_role_resource urr ON urr.resource_id = rh.id
         WHERE urr.user_id = chmod._admin_user_id
           AND urr.role_id = _admin_role_id
                 )
      INTO _has_admin_permission;

    IF NOT _has_admin_permission THEN
        RAISE EXCEPTION 'Admin User "%" does not have "admin" permissions on resource "%" or any parent folders.', chmod._admin_user_id, chmod._resource_id;
    END IF;
    /*
	 * Business logic:
	 * - Insert or update the user-role-resource relationship
	 * - Return the modified user_role_resource record
	 */

    -- Insert or update the user-role-resource relationship
    INSERT
      INTO user_role_resource (resource_id, user_id, role_id)
    VALUES (chmod._resource_id, chmod._user_id, _role_id)
        ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;

    RAISE NOTICE 'Role "%" assigned to user "%" for resource id "%"', chmod._role_type, chmod._user_id, chmod._resource_id;

    RETURN QUERY SELECT *
                   FROM user_role_resource urr
                  WHERE urr.resource_id = chmod._resource_id AND urr.user_id = chmod._user_id;
END;


$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION chmod IS 'Change user role attached to a resource.

Parameters:
- _resource_id (INTEGER): The ID of the resource (file or folder) to which the role should be assigned.
- _user_id (INTEGER): The ID of the user to which to assign the resource-role.
- _role_type (ROLE): The role type to be assigned to the user.

Returns:
- the modified user_role_resource record';


COMMIT;
