SET search_path TO virtual_file_system, public;

CREATE OR REPLACE FUNCTION virtual_file_system.public.resources_ownership_assignment_on_insert() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
DECLARE
    _user_id          INTEGER  := new.created_by;
    _resource_id      INTEGER  := new.id;
    _owner_role_id    SMALLINT := (
                                      SELECT r.id AS role_id
                                        FROM virtual_file_system.public.roles r
                                       WHERE r.name = 'owner'
                                  );
    _admin_role_id    SMALLINT := (
                                      SELECT r.id AS role_id
                                        FROM virtual_file_system.public.roles r
                                       WHERE r.name = 'admin'
                                  );
    _parent_folder_id INTEGER  := (
                                      SELECT re.parent_folder_id
                                        FROM virtual_file_system.public.resources re
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
COMMENT ON FUNCTION virtual_file_system.public.resources_ownership_assignment_on_insert() IS 'Automatically assigns roles to a user creating a resource.
	- Assigns the "admin" role to a user creating a root resource
    - and the "owner" role to a user creating a non-root resource.';


-- resources_ownership_assignment_trigger

DROP TRIGGER IF EXISTS resources_ownership_assignment_trigger ON resources;
CREATE TRIGGER resources_ownership_assignment_trigger
    AFTER INSERT
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION virtual_file_system.public.resources_ownership_assignment_on_insert();
COMMENT ON TRIGGER resources_ownership_assignment_trigger ON resources IS 'Trigger to automatically assign the "owner" role to the user who creates a resource.';
