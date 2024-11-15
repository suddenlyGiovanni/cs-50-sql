SET search_path TO virtual_file_system, public;

DROP TYPE IF EXISTS ROLE_TYPE;

DO
$$
    BEGIN
        IF NOT exists (
            SELECT 1
              FROM pg_type
             WHERE typname = 'PERMISSION_TYPE'
                      ) THEN CREATE TYPE PERMISSION_TYPE AS ENUM ('read', 'write', 'delete', 'manage');
        END IF;
    END
$$;

COMMENT ON TYPE PERMISSION_TYPE IS 'The type of permission a user can have on a resource.
    Read allows the user to read the resource,
    Write allows the user to update the resource,
    Delete allows the user to delete the resource,
    Manage allows the user to change the access control of the resource.';
