DO
$$
    BEGIN
        CREATE DATABASE virtual_file_system;
    EXCEPTION
        WHEN duplicate_database THEN RAISE NOTICE 'Database virtual_file_system already exists.';
    END
$$;
