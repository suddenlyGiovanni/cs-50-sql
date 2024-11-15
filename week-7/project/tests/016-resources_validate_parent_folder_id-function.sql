SET search_path TO virtual_file_system, public;

-- Unit test for resources_validate_parent_folder_id_trigger
DO
$$
    DECLARE
        -- users
        _random_uuid           UUID    := gen_random_uuid();
        _user_name             VARCHAR := 'test_user_' || _random_uuid;
        _user_email            VARCHAR := _user_name || '@test.com';
        _user_id               INT;

        -- resources
        _resources_folder_a_id INT;
        _resources_folder_b_id INT;
        _resources_file_a_id   INT;
        _resources_file_b_id   INT;

        -- folders
        _folder_a_id           INT;
        _folder_a_name         VARCHAR := 'test_folder_' || _random_uuid || '_a';
        _folder_b_id           INT;
        _folder_b_name         VARCHAR := 'test_folder_' || _random_uuid || '_b';


        -- files
        _file_a_id             INT;
    BEGIN
        RAISE NOTICE 'Running `resources_validate_parent_folder_id_trigger` tests';
        -- Outer block to handle exceptions and ensure cleanup
        BEGIN
            -- Create a test user
               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_name, _user_email, _random_uuid)
            RETURNING id INTO _user_id;

            -- DESCRIBE: Folder validation:
            -- Test 1: Should be able to create a top-level folder
            BEGIN
                   INSERT
                     INTO resources (type, created_by, updated_by, parent_folder_id)
                   VALUES ('folder', _user_id, _user_id, NULL) -- top-level folder
                RETURNING id INTO _resources_folder_a_id;

                   INSERT
                     INTO folders (resource_id, name)
                   VALUES (_resources_folder_a_id, _folder_a_name)
                RETURNING id INTO _folder_a_id;

                RAISE NOTICE 'Test 1 passed: "Should be able to create a top-level folder"';
            EXCEPTION
                WHEN OTHERS THEN RAISE NOTICE 'Test 1 failed: "Should be able to create a top-level folder" - Unexpected exception: %', sqlerrm;
            END;


            -- Test 2: Should be able to insert a folder with a valid parent folder
            BEGIN
                INSERT
                  INTO user_role_resource (user_id, role_id, resource_id)
                VALUES (_user_id, (
                    SELECT roles.id
                      FROM roles
                     WHERE roles.name = 'editor'
                                  ), _resources_folder_a_id);

                   INSERT
                     INTO resources (type, created_by, updated_by, parent_folder_id)
                   VALUES ('folder', _user_id, _user_id, _resources_folder_a_id)
                RETURNING id INTO _resources_folder_b_id;

                   INSERT
                     INTO folders (resource_id, name)
                   VALUES (_resources_folder_b_id, _folder_b_name)
                RETURNING id INTO _folder_b_id;

                RAISE NOTICE 'Test 2 passed: "Should be able to insert a folder with a valid parent folder"';
            EXCEPTION
                WHEN OTHERS THEN RAISE NOTICE 'Test 2 failed: "Should be able to insert a folder with a valid parent folder" - Unexpected exception: %', sqlerrm;
            END;

            -- Test 3: Should fail to Insert a folder with a non-existent parent folder
            BEGIN
                INSERT
                  INTO resources (type, created_by, updated_by, parent_folder_id)
                VALUES ('folder', _user_id, _user_id, 99999);
                RAISE EXCEPTION 'Test 3 failed: "Should fail to Insert a folder with a non-existent parent folder"';
            EXCEPTION
                WHEN OTHERS THEN RAISE NOTICE 'Test 3 passed: "Should fail to Insert a folder with a non-existent parent folder" - Caught exception: %', sqlerrm;
            END;


            -- DESCRIBE: File validation:
            -- Test 4: Should be able to insert a file with a valid parent folder
            BEGIN
                   INSERT
                     INTO resources (type, created_by, updated_by, parent_folder_id)
                   VALUES ('file', _user_id, _user_id, _resources_folder_a_id)
                RETURNING id INTO _resources_file_a_id;

                   INSERT
                     INTO files (resource_id, name, mime_type, storage_path)
                   VALUES (_resources_file_a_id, 'test_file_a', 'text/plain', 'test_file_a.txt')
                RETURNING id INTO _file_a_id;

                RAISE NOTICE 'Test 4 passed: "Should be able to insert a file with a valid parent folder"';
            EXCEPTION
                WHEN OTHERS THEN RAISE NOTICE 'Test 4 failed: "Should be able to insert a file with a valid parent folder" - Unexpected exception: %', sqlerrm;
            END;

            -- Test 5: Should fail to insert a file with a NULL parent folder
            BEGIN
                   INSERT
                     INTO resources (type, created_by, updated_by, parent_folder_id)
                   VALUES ('file', _user_id, _user_id, NULL)
                RETURNING id
                    INTO _resources_file_b_id;

                RAISE EXCEPTION 'File with NULL parent folder inserted';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'A file resource must have a parent folder' THEN
                    RAISE NOTICE 'Test 5 passed: "Should fail to insert a file with a NULL parent folder" - Expected exception: %', sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 5 failed: "Should fail to insert a file with a NULL parent folder": - Unexpected exception: %', sqlerrm;
                END IF;
            END;


            -- Test 6: Should fail to insert a file with an existing parent_folder_id but of the wrong type
            BEGIN
                INSERT
                  INTO resources (type, created_by, updated_by, parent_folder_id)
                VALUES ('file', _user_id, _user_id, _resources_file_a_id);
                RAISE EXCEPTION 'Failed to raise validation exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'Parent folder with id "%" does not exist' THEN
                    RAISE NOTICE 'Test 6 passed: "Should fail to insert a file with an existing parent_folder_id but of the wrong type": Expected exception: %', sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 6 failed: "Should fail to insert a file with an existing parent_folder_id but of the wrong type" - Unexpected exception: %', sqlerrm;
                END IF;
            END;


        EXCEPTION
            WHEN OTHERS THEN RAISE EXCEPTION 'Unit test failed: %', sqlerrm;
        END;

        -- Tear down: Cleanup test data
        BEGIN
            DELETE FROM folders WHERE name LIKE 'test_folder_' || _random_uuid || '_%';
            DELETE FROM resources WHERE created_by = _user_id;
            DELETE FROM users WHERE id = _user_id;
            RAISE NOTICE 'Cleanup `resources_validate_parent_folder_id_trigger` test data completed';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Cleanup failed: %', sqlerrm;
        END;
    END;
$$ LANGUAGE plpgsql;
