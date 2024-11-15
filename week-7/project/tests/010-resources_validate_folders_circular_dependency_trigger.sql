-- Unit test for resources_validate_folders_circular_dependency_trigger
DO
$$
    DECLARE
        _random_uuid           VARCHAR := gen_random_uuid();

        -- users:
        _user_id               INT;
        _user_name             VARCHAR := 'test_user_' || _random_uuid;
        _user_email            VARCHAR := _user_name || '@test.com';

        -- resources:
        _resources_folder_a_id INT;
        _resources_folder_b_id INT;

        -- folders:
        _folder_a_id           INT;
        _test_folder_a_name    VARCHAR := 'test_folder_' || _random_uuid || '_a';
        _folder_b_id           INT;
        _test_folder_b_name    VARCHAR := 'test_folder_' || _random_uuid || '_b';

    BEGIN
        -- Outer block to handle exceptions and ensure cleanup
        RAISE NOTICE 'Running `resources_validate_folders_circular_dependency_trigger` tests';
        BEGIN

            -- Arrange
            -- Create a test user
               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_name, _user_email, _random_uuid)
            RETURNING id INTO _user_id;


            -- Create a top-level folder
               INSERT
                 INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('folder', _user_id, _user_id, NULL) -- Root folder, parent_folder_id is NULL
            RETURNING id INTO _resources_folder_a_id;


              WITH admin_role AS (
                  SELECT roles.id AS role_id
                    FROM roles
                   WHERE roles.name = 'admin'
                                 )
            INSERT
              INTO user_role_resource (user_id, role_id, resource_id)
            VALUES (_user_id, (
                SELECT role_id
                  FROM admin_role
                              ), _resources_folder_a_id)
                ON CONFLICT (user_id, resource_id) DO UPDATE SET role_id = excluded.role_id;

               INSERT
                 INTO folders (resource_id, name)
               VALUES (_resources_folder_a_id, _test_folder_a_name)
            RETURNING id INTO _folder_a_id;


            -- Create a folder inside the folder_a
               INSERT
                 INTO resources (type, created_by, updated_by, parent_folder_id)
               VALUES ('folder', _user_id, _user_id, _resources_folder_a_id) -- Correct parent_folder_id
            RETURNING id INTO _resources_folder_b_id;

               INSERT
                 INTO folders (resource_id, name)
               VALUES (_resources_folder_b_id, _test_folder_b_name)
            RETURNING id INTO _folder_b_id;


            --  Act: insert a folder creating a circular dependency.
            -- Assert: Should fail to insert a resource that creates a circular dependency.
            BEGIN
                UPDATE resources
                   SET parent_folder_id = _resources_folder_b_id
                 WHERE id = _resources_folder_a_id; -- Intentional circular dependency
                RAISE EXCEPTION 'Validation trigger failed to detect circular dependency';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'Circular dependency detected in the folders table' THEN
                    RAISE NOTICE 'Test 1 passed: "Should fail to insert a resource that creates a circular dependency" - Expected exception: %', sqlerrm;
                ELSE
                    RAISE EXCEPTION 'Test 1 failed: "Should fail to insert a resource that creates a circular dependency" - Unexpected exception: %', sqlerrm;
                END IF;
            END;

        EXCEPTION
            WHEN OTHERS THEN RAISE EXCEPTION 'Unit test failed: %', sqlerrm;
        END;

        -- Tear down: Cleanup test data
        BEGIN
            DELETE FROM resources WHERE id = _resources_folder_b_id; -- should cascade delete folders 'test_folder_b';
            DELETE FROM resources WHERE id = _resources_folder_a_id; -- should cascade delete folders 'test_folder_a'
            DELETE FROM users WHERE id = _user_id;
            RAISE NOTICE 'Cleanup `resources_validate_folders_circular_dependency_trigger` test data completed';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Cleanup failed: %', sqlerrm;
        END;
    END
$$ LANGUAGE plpgsql;
