SET search_path TO virtual_file_system, public;

BEGIN;

DO
$$
    BEGIN
        IF NOT exists (
            SELECT 1
              FROM pg_type
             WHERE typname = 'PERMISSION'
                      ) THEN CREATE TYPE PERMISSION AS ENUM ('read', 'write', 'delete', 'manage');
        END IF;
    END
$$;

COMMENT ON TYPE PERMISSION IS 'The type of permission a user can have on a resource.
    Read allows the user to read the resource,
    Write allows the user to update the resource,
    Delete allows the user to delete the resource,
    Manage allows the user to change the access control of the resource.';

COMMIT;
