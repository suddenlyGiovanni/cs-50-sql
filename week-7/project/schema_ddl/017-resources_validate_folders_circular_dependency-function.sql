SET search_path TO virtual_file_system, public;

BEGIN;;

CREATE OR REPLACE FUNCTION resources_validate_folders_circular_dependency() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
DECLARE
    _exists_cycle BOOLEAN;
BEGIN
    --  Prevent circular dependency in the folders table
    --  validate only if parent_folder_id is not null=
    IF new.parent_folder_id IS NULL THEN
        RETURN new; --
    END IF;


      WITH RECURSIVE folder_tree AS (
          -- Start with the new folder's parent folder
          SELECT new.parent_folder_id AS folder_id
           UNION
-- Recursively add parent folder to the folder tree
          SELECT r.parent_folder_id
            FROM resources r
                JOIN folder_tree ON r.id = folder_tree.folder_id
                                    )
-- Check if the new folder ID appears in the hierarchy, indicating a cycle
    SELECT exists(
        SELECT 1 --
          FROM folder_tree --
         WHERE folder_tree.folder_id = new.id
                 )
      INTO _exists_cycle;

    -- If a cycle is detected, raise an exception
    IF _exists_cycle THEN
        RAISE EXCEPTION 'Circular dependency detected in the folders table'; --
    END IF;

    RETURN new;
END;
$$;

COMMENT ON FUNCTION resources_validate_folders_circular_dependency IS 'Prevent circular dependency in the folders table';

COMMIT;
