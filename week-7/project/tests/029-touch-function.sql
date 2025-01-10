-- Set the search path to include your schema
SET search_path TO virtual_file_system, public;


-- Test 01: Should fail to create a file for a non-existent user
BEGIN;
DO
$$
    DECLARE
        _random_uuid              UUID := gen_random_uuid();
        _user_id                  INTEGER;
        _user_id_invalid          INTEGER;
        _folder_id                INTEGER;
        _exception_message        TEXT;
        _resources_id_root_folder INTEGER;
    BEGIN

        -- Create a root test user
           INSERT
             INTO users (username, email, hashed_password)
           VALUES ('test_user_' || _random_uuid, 'test_user_' || _random_uuid || '@test.com', _random_uuid)
        RETURNING id INTO _user_id;


        -- Arrange: Set an invalid user ID (assuming negative IDs are invalid)
        _user_id_invalid := (
            SELECT floor(random() * (9999999 - 1000000 + 1) + 1000000)::INT
                            );

        -- Confirm that the invalid user does not exist
        IF exists (
            SELECT 1
              FROM users
             WHERE id = _user_id_invalid
                  ) THEN
            RAISE EXCEPTION 'Test 01: Setup error: _invalid_user_id % already exists.', _user_id_invalid;
        END IF;

        SELECT mkdir('test_folder_' || _random_uuid, (
            SELECT u.username
              FROM users u
             WHERE u.id = _user_id
                                                     ), 'admin', NULL)
          INTO _folder_id;

        _resources_id_root_folder := (
            SELECT f.resource_id
              FROM folders f
             WHERE f.id = _folder_id
                                     );


        -- Act and Assert: Attempt to create a file with the invalid user ID
        BEGIN
            PERFORM touch(_user_id_invalid --
                , 'test_file_' || _random_uuid --
                , 'text/plain' --
                , _resources_id_root_folder --
                , '/path/to/' || 'test_file_' || _random_uuid --
                , 1024 --
                    );
            -- If no exception is raised, the test fails
            RAISE EXCEPTION 'Test 01 failed: No exception raised for non-existent user.';
        EXCEPTION
            WHEN OTHERS THEN
                -- Capture the exception message
                _exception_message := sqlerrm;

                -- Check if the exception message matches the expected pattern
                IF _exception_message LIKE 'User "%" %does not exist%' THEN
                    RAISE NOTICE 'Test 01 passed: Expected exception caught - %', _exception_message;
                ELSE
                    RAISE EXCEPTION 'Test 01 failed: Unexpected exception - %', _exception_message;
                END IF;
        END;
        -- Tear down: Cleanup test data
        DELETE
          FROM virtual_file_system.public.resources r
         WHERE r.id = (
             SELECT f.resource_id
               FROM folders f
              WHERE f.id = _folder_id
                      );
        DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_id;
    END;
$$ LANGUAGE plpgsql;
-- Test 01: Roll back the transaction to leave the database unchanged
ROLLBACK;


-- Test 02: Should fail to create a file in a non-existent parent folder
BEGIN;
DO
$$
    DECLARE
        _user_id                     INTEGER;
        _random_uuid                 UUID := gen_random_uuid();
        _resources_folder_id_invalid INT  := (
                                                 SELECT floor(random() * (9999999 - 1000000 + 1) + 1000000)::INT
                                             );


    BEGIN
        -- Arrange:
        -- Confirm that the invalid folder does not exist
        IF exists (
            SELECT 1 FROM folders f WHERE f.resource_id = _resources_folder_id_invalid
                  ) THEN
            RAISE EXCEPTION 'Test 02: Setup error: _invalid_resources_folder_id % already exists.', _resources_folder_id_invalid;
        END IF;

        -- Create a root test user
           INSERT
             INTO users (username, email, hashed_password)
           VALUES ('test_user_' || _random_uuid, 'test_user_' || _random_uuid || '@test.com', _random_uuid)
        RETURNING id INTO _user_id;


        -- Act and Assert
        PERFORM touch( --
                _user_id --
            , 'test_file_' || _random_uuid --
            , 'text/plain' --
            , _resources_folder_id_invalid --
            , '/path/to/' || 'test_file_' || _random_uuid --
            , 1024 --
                );
        RAISE EXCEPTION 'Validation for wrong parent_folder_id failed to raise exception';
    EXCEPTION
        WHEN OTHERS THEN IF sqlerrm LIKE 'Parent folder with id "%" does not exist' THEN
            RAISE NOTICE 'Test 02 passed: "Should fail to create a File for a non-existent parent folder" - Expected exception: %',sqlerrm;
        ELSE
            RAISE NOTICE 'Test 02 failed: "Should fail to create a File for a non-existent parent folder" - Unexpected exception: %', sqlerrm;
        END IF;

        -- Tear down: Cleanup test data
        DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_id;
    END;
$$ LANGUAGE plpgsql;
-- Test 02: Roll back the transaction to leave the database unchanged
ROLLBACK;


-- Test 03: Should fail to create a file in a parent resource that is not a folder
BEGIN;
DO
$$
    DECLARE
        _user_id                   INTEGER;
        _random_uuid               UUID := gen_random_uuid();
        _folder_id                 INTEGER;
        _resources_file_id_invalid INTEGER;
        _resources_id_root_folder  INTEGER;

    BEGIN
        -- Arrange:
           INSERT
             INTO users (username, email, hashed_password)
           VALUES ( 'test_user_' || _random_uuid --
                  , 'test_user_' || _random_uuid || '@test.com' --
                  , _random_uuid)
        RETURNING id INTO _user_id;

        SELECT mkdir('test_folder_' || _random_uuid, (
            SELECT u.username
              FROM users u
             WHERE u.id = _user_id
                                                     ), 'admin', NULL)
          INTO _folder_id;

        _resources_id_root_folder := (
            SELECT f.resource_id
              FROM folders f
             WHERE f.id = _folder_id
                                     );

           INSERT
             INTO resources (type, created_by, updated_by, parent_folder_id)
           VALUES ('file', _user_id, _user_id, _resources_id_root_folder)
        RETURNING resources.id INTO _resources_file_id_invalid;

        -- Act and Assert
        PERFORM touch( --
                _user_id --
            , 'test_file_' || _random_uuid --
            , 'text/plain' --
            , _resources_file_id_invalid --
            , '/path/to/' || 'test_file_' || _random_uuid--
            , 1024 --
                );
        RAISE EXCEPTION 'Validation for wrong parent_folder_id failed to raise exception';
    EXCEPTION
        WHEN OTHERS THEN IF sqlerrm LIKE 'Parent folder with id "%" does not exist' THEN
            RAISE NOTICE 'Test 03 passed: "Should fail to create a File for a parent folder of wrong type" - Expected exception: %',sqlerrm;
        ELSE
            RAISE NOTICE 'Test 03 failed: "Should fail to create a File for a parent folder of wrong type" - Unexpected exception: %', sqlerrm;
        END IF;


        -- Tear down: Cleanup test data
        DELETE FROM resources r WHERE r.id = _resources_file_id_invalid;
        DELETE FROM resources r WHERE r.id = _resources_id_root_folder;
        DELETE FROM users u WHERE u.id = _user_id;
    END;
$$ LANGUAGE plpgsql;
-- Test 03: Roll back the transaction to leave the database unchanged
ROLLBACK;


-- Test 04: Should fail to crate a file when a file with the same name already exists in the parent folder
BEGIN;
DO
$$
    DECLARE
        _user_id                     INTEGER;
        _random_uuid                 UUID    := gen_random_uuid();
        _user_name_valid             TEXT    := 'test_user_' || _random_uuid;
        _user_email_valid            TEXT    := _user_name_valid || '@test.com';
        _file_name_duplicated        TEXT    := 'test_file_' || _random_uuid;
        _content_type                TEXT    := 'text/plain';
        _file_path                   TEXT    := '/path/to/' || _file_name_duplicated;
        _file_size                   INTEGER := 1024;
        _folder_id                   INTEGER;
        _resources_file_id_same_name INTEGER;
        _resources_id_root_folder    INTEGER;

    BEGIN
        -- Arrange:
           INSERT
             INTO users (username, email, hashed_password)
           VALUES (_user_name_valid, _user_email_valid, _random_uuid)
        RETURNING id INTO _user_id;

        SELECT mkdir('test_folder_' || _random_uuid, (
            SELECT u.username
              FROM users u
             WHERE u.id = _user_id
                                                     ), 'owner', NULL)
          INTO _folder_id;

        _resources_id_root_folder := (
            SELECT f.resource_id
              FROM folders f
             WHERE f.id = _folder_id
                                     );


        -- create a file resource
           INSERT
             INTO resources (type, created_by, updated_by, parent_folder_id)
           VALUES ('file', _user_id, _user_id, _resources_id_root_folder)
        RETURNING resources.id INTO _resources_file_id_same_name;

        -- crate a file with an arbitrary name
        INSERT
          INTO files (resource_id, name, mime_type, storage_path)
        VALUES (_resources_file_id_same_name, _file_name_duplicated, _content_type, _file_path);

        -- Act and Assert
        PERFORM touch( --
                _user_id --
            , _file_name_duplicated --
            , _content_type--
            , _resources_id_root_folder --
            , _file_path--
            , _file_size --
                );
        RAISE EXCEPTION 'Validation for unique file name failed to raise exception';
    EXCEPTION
        WHEN OTHERS THEN IF sqlerrm LIKE 'File with name "%" already exists in the parent folder "%"' THEN
            RAISE NOTICE 'Test 04 passed: "Should fail to create a File for an already existing file resource with the same name" - Expected exception: %',sqlerrm;
        ELSE
            RAISE NOTICE 'Test 04 failed: "Should fail to create a File for an already existing file resource with the same name" - Unexpected exception: %', sqlerrm;
        END IF;

        -- Tear down: Cleanup test data
        DELETE FROM resources r WHERE r.id = _resources_file_id_same_name;
        DELETE FROM resources r WHERE r.id = _resources_id_root_folder;
        DELETE FROM users u WHERE u.id = _user_id;
    END;
$$ LANGUAGE plpgsql;
-- Test 04: Roll back the transaction to leave the database unchanged
ROLLBACK;


-- Test 05: Should fail to crate a file when the user has no write permission on the parent_folder_id
BEGIN;
DO
$$
    DECLARE
        _user_id_a                INTEGER;
        _user_id_b                INTEGER;
        _random_uuid_a            UUID := gen_random_uuid();
        _random_uuid_b            UUID := gen_random_uuid();
        _folder_id                INTEGER;
        _resources_id_root_folder INTEGER;

    BEGIN
        -- Arrange:
           INSERT
             INTO users (username, email, hashed_password)
           VALUES ('test_user_' || _random_uuid_a, 'test_user_' || _random_uuid_a || '@test.com', _random_uuid_a)
        RETURNING id INTO _user_id_a;

           INSERT
             INTO users (username, email, hashed_password)
           VALUES ('test_user_' || _random_uuid_b, 'test_user_' || _random_uuid_b || '@test.com', _random_uuid_b)
        RETURNING users.id INTO _user_id_b;

        SELECT mkdir('test_folder_' || _random_uuid_a, (
            SELECT u.username
              FROM users u
             WHERE u.id = _user_id_a
                                                       ), 'owner', NULL)
          INTO _folder_id;

        _resources_id_root_folder := (
            SELECT f.resource_id
              FROM folders f
             WHERE f.id = _folder_id
                                     );

        INSERT
          INTO user_role_resource (resource_id, user_id, role_id)
        VALUES ( _resources_id_root_folder --
               , _user_id_b --
               , (
                     SELECT r.id
                       FROM roles r
                      WHERE r.name = 'viewer'::ROLE
                 ))
            ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;


        -- Act and Assert
        PERFORM touch( --
                _user_id_b --
            , 'test_file_' || _random_uuid_b --
            , 'text/plain' --
            , _resources_id_root_folder -- for which the user has no write permission
            , '/path/to/' || 'test_file_' || _random_uuid_b --
            , 1024 --
                );

        -- Assert
        RAISE EXCEPTION 'Validation for write permission failed to raise exception';
    EXCEPTION
        WHEN OTHERS THEN IF sqlerrm LIKE 'User "%" does not have write permission on the parent folder "%"' THEN
            RAISE NOTICE 'Test 05 passed: "Should fail to crate a file when the user has no write permission on the parent_folder_id" - Expected exception: %',sqlerrm;
        ELSE
            RAISE NOTICE 'Test 05 failed: "Should fail to crate a file when the user has no write permission on the parent_folder_id" - Unexpected exception: %', sqlerrm;
        END IF;

        -- Tear down: Cleanup test data
        DELETE FROM resources r WHERE r.id = _resources_id_root_folder;
        DELETE FROM users u WHERE u.id = _user_id_b;
        DELETE FROM users u WHERE u.id = _user_id_a;
    END;
$$ LANGUAGE plpgsql;
-- Test 05: Roll back the transaction to leave the database unchanged
ROLLBACK;


-- Test 0?: Should assign to the file resource the same access role as its parent folder resource
BEGIN;
DO
$$
    DECLARE
        _user_id                  INTEGER;
        _random_uuid              UUID := gen_random_uuid();
        _folder_id                INTEGER;
        _resources_id_root_folder INTEGER;
        _resource_id_file         INTEGER;

    BEGIN
        -- Arrange:
           INSERT
             INTO users (username, email, hashed_password)
           VALUES ( 'test_user_' || _random_uuid --
                  , 'test_user_' || _random_uuid || '@test.com' --
                  , _random_uuid)
        RETURNING id INTO _user_id;

        SELECT mkdir('test_folder_' || _random_uuid, (
            SELECT u.username
              FROM users u
             WHERE u.id = _user_id
                                                     ), 'admin'::ROLE, NULL)
          INTO _folder_id;

        _resources_id_root_folder := (
            SELECT f.resource_id
              FROM folders f
             WHERE f.id = _folder_id
                                     );

        -- Act
        SELECT touch( --
                       _user_id, --
                       'test_file_' || _random_uuid, --
                       'text/plain', --
                       _resources_id_root_folder, --
                       '/path/to/' || 'test_file_' || _random_uuid, --
                       1024 --
               )
          INTO _resource_id_file;

        -- Assert
        -- check if the file resource has the same role as the parent folder
        IF NOT exists (
            SELECT 1
              FROM user_role_resource urr
             WHERE urr.resource_id = _resource_id_file
               AND urr.role_id = (
                 SELECT r.id
                   FROM roles r
                  WHERE r.name = 'admin'::ROLE
                                 )
                      ) THEN
            RAISE EXCEPTION 'Test 0? failed: "Should assign to the file resource the same access role as its parent folder resource"';
        ELSE
            RAISE NOTICE 'Test 0? passed: "Should assign to the file resource the same access role as its parent folder resource"';
        END IF;


        -- Tear down: Cleanup test data
        DELETE FROM resources r WHERE r.id = _resource_id_file;
        DELETE FROM resources r WHERE r.id = _resources_id_root_folder;
        DELETE FROM users u WHERE u.id = _user_id;
    END;
$$ LANGUAGE plpgsql;
-- Test 0?: Roll back the transaction to leave the database unchanged
ROLLBACK;
