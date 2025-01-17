SET search_path TO virtual_file_system, public;

BEGIN;;

CREATE OR REPLACE FUNCTION resources_ownership_assignment_on_insert() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
DECLARE
    _user_id          INTEGER  := new.created_by;
    _resource_id      INTEGER  := new.id;
    _owner_role_id    SMALLINT := (
                                      SELECT r.id AS role_id
                                        FROM roles r
                                       WHERE r.name = 'owner'
                                  );
    _admin_role_id    SMALLINT := (
                                      SELECT r.id AS role_id
                                        FROM roles r
                                       WHERE r.name = 'admin'
                                  );
    _parent_folder_id INTEGER  := (
                                      SELECT re.parent_folder_id
                                        FROM resources re
                                       WHERE re.id = new.id
                                  );
BEGIN
    -- Insert the user-role-resource mapping
    -- If it fails, the entire transaction will be rolled back

    IF (_parent_folder_id ISNULL) THEN
        INSERT
          INTO user_role_resource (resource_id, user_id, role_id) --
        VALUES (_resource_id, _user_id, _admin_role_id)
            ON CONFLICT (resource_id, user_id ) DO NOTHING;
    ELSE
        INSERT
          INTO user_role_resource (resource_id, user_id, role_id) --
        VALUES (_resource_id, _user_id, _owner_role_id)
            ON CONFLICT (resource_id, user_id ) DO NOTHING;
    END IF;

    RETURN new;
END;
$$;

COMMENT ON FUNCTION resources_ownership_assignment_on_insert() IS 'Automatically assigns roles to a user creating a resource.
	- Assigns the "admin" role to a user creating a root resource
    - and the "owner" role to a user creating a non-root resource.';

COMMIT;
