CREATE OR REPLACE FUNCTION resources_validate_folders_circular_dependency() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
BEGIN
    --  Prevent circular dependency in the folders table
    --  validate only if parent_folder_id is not null=

    RETURN new;
END;
$$;
COMMENT ON FUNCTION resources_validate_folders_circular_dependency IS 'Prevent circular dependency in the folders table';


CREATE OR REPLACE TRIGGER resources_validate_folders_circular_dependency_trigger
    BEFORE INSERT OR UPDATE OF parent_folder_id
    ON resources
    FOR EACH ROW
EXECUTE FUNCTION resources_validate_folders_circular_dependency();
