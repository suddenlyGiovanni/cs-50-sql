SET search_path TO virtual_file_system, public;

/**
 * Unit test for touch function:
 * Should be able to create the following folder structure:
 *
 */
DO
$$
    DECLARE
        -- users:
        _random_uuid         UUID     := gen_random_uuid();
        _user_name           VARCHAR  := 'test_user_' || _random_uuid;
        _user_email          VARCHAR  := _user_name || '@test.com';
        _user_id             INT;
        _invalid_user_id     INT      := (
                                             SELECT floor(random() * (9999999 - 1000000 + 1) + 1000000)::INT
                                         );

        -- resources:
        _resources_folder_id INT;

        -- folders
        _folder_name         VARCHAR  := 'test_folder_' || _random_uuid;
        _folder_id           INT;


        -- roles:
        _owner_role_id       SMALLINT := (
                                             SELECT id
                                               FROM roles
                                              WHERE name = 'owner'::ROLE
                                         );

    BEGIN
        -- Outer block to handle exceptions and ensure cleanup
        BEGIN
            -- ARRANGE:
            -- Create a test user
               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_name, _user_email, _random_uuid)
            RETURNING id INTO _user_id;


            -- Create a test folder "_folder" with the `owner` role
               INSERT
                 INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('folder', _user_id, _user_id, NULL)
            RETURNING resources.id INTO _resources_folder_id;

               INSERT
                 INTO folders (resource_id, name)
               VALUES (_resources_folder_id, _folder_name)
            RETURNING folders.id INTO _folder_id;


            INSERT
              INTO user_role_resource (resource_id, user_id, role_id)
            VALUES (_resources_folder_id, _user_id, _owner_role_id)
                ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;

            -- validation test conditions
            -- invalid user_id

            -- Test 01: Should fail to create a file for a non-existent user
            BEGIN
                PERFORM touch( --
                        _invalid_user_id, --
                        'non_existent_user_test_file', --
                        'text/plain', --
                        _resources_folder_id, --
                        '/path/to/file', --
                        1024 --
                        );
                RAISE EXCEPTION 'Validation for non-existent user failed to raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'User "%" does not exist' THEN
                    RAISE NOTICE 'Test 01 passed: "Should fail to create a File for a non-existent user" - Expected exception: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 01 failed: "Should fail to create a File for a non-existent user" - Unexpected exception: %', sqlerrm;
                END IF;
            END;


        EXCEPTION
            WHEN OTHERS THEN --
                RAISE NOTICE 'Exception: %', sqlerrm;
            -- Ensure that the exception won't prevent execution of the cleanup section
        END;

        -- Tear down: Cleanup test data
        BEGIN
            DELETE FROM virtual_file_system.public.files f WHERE f.id = _folder_id;
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_id;
            DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_id;
            RAISE NOTICE 'Cleanup `touch` test data completed';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Cleanup failed: %', sqlerrm;
        END;
    END;
$$;
