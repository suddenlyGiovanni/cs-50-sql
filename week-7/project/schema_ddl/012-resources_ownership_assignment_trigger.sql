CREATE OR REPLACE FUNCTION virtual_file_system.public.resources_ownership_assignment_on_insert() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
DECLARE
    _user_id     INTEGER := new.created_by;
    _resource_id INTEGER := new.id;
BEGIN
    -- Insert the user-role-resource mapping
    -- If it fails, the entire transaction will be rolled back
      WITH owner_role AS (
          SELECT roles.id AS role_id
            FROM roles
           WHERE roles.name = 'owner'
                         )
    INSERT
      INTO user_role_resource (resource_id, user_id, role_id) --
    VALUES (_resource_id, _user_id, (
        SELECT role_id
          FROM owner_role
                                    ))
        ON CONFLICT DO NOTHING;
    RETURN new;
END;
$$;
COMMENT ON FUNCTION virtual_file_system.public.resources_ownership_assignment_on_insert() IS 'Automatically assigns the "owner" role to a resource for the user who created it.';


-- resources_ownership_assignment_trigger

DROP TRIGGER IF EXISTS resources_ownership_assignment_trigger ON resources;
CREATE TRIGGER resources_ownership_assignment_trigger
    AFTER INSERT
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION virtual_file_system.public.resources_ownership_assignment_on_insert();
COMMENT ON TRIGGER resources_ownership_assignment_trigger ON resources IS 'Trigger to automatically assign the "owner" role to the user who creates a resource.';
