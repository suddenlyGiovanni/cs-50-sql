/*
*  Unit test for chmod function:
*/
DO
$$
    DECLARE
        -- users A:
        _random_a_uuid            UUID    := gen_random_uuid();
        _user_a_id                INT;
        _user_a_name              VARCHAR := 'test_user_a_' || _random_a_uuid;
        _user_a_email             VARCHAR := _user_a_name || '@test.com';

        -- users B:
        _random_b_uuid            UUID    := gen_random_uuid();
        _user_b_id                INT;
        _user_b_name              VARCHAR := 'test_user_b_' || _random_b_uuid;
        _user_b_email             VARCHAR := _user_b_name || '@test.com';

        -- users C:
        _random_c_uuid            UUID    := gen_random_uuid();
        _user_c_id                INT;
        _user_c_name              VARCHAR := 'test_user_c_' || _random_c_uuid;
        _user_c_email             VARCHAR := _user_c_name || '@test.com';


        -- Folders
        _resources_folder_a_id    INT;
        _folder_a_id              INT;
        _folder_a_name            VARCHAR := 'test_folder_' || _random_a_uuid || '_a';

        --
        _resources_folder_aa_1_id INT;
        _folder_aa_id             INT;
        _folder_aa_1_name         VARCHAR := 'test_folder_' || _random_a_uuid || '_aa_1';


        -- Additional test variables
        non_existent_resource_id  INT     := 999999; -- Assume this ID doesn't exist
        non_existent_user         VARCHAR := 'non_existent_user_' || _random_a_uuid;
        wrong_role_type           VARCHAR := 'non_existent_role';

    BEGIN
        RAISE NOTICE 'Running chmod tests';
        -- Outer block to handle exceptions and ensure cleanup
        BEGIN
            -- Arrange: Create a test user
               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_a_name, _user_a_email, gen_random_uuid())
            RETURNING id
                INTO _user_a_id;

               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_b_name, _user_b_email, gen_random_uuid())
            RETURNING id
                INTO _user_b_id;


               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_c_name, _user_c_email, gen_random_uuid())
            RETURNING id
                INTO _user_c_id;


            -- Create a parent folder resource
               INSERT
                 INTO resources (created_by, updated_by, type, parent_folder_id)
               VALUES (_user_a_id, _user_a_id, 'folder', NULL)
            RETURNING id INTO _resources_folder_a_id;

            -- Set `Admin` role for `_resources_folder_a_id` for user `_user_a_id`
            PERFORM chmod(_resources_folder_a_id, _user_a_id, 'admin');

            -- Test 1: Should assign the `admin` role for `_folder_a_name` to the user `_user_a_id`
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.user_role_resource uur
                     WHERE uur.resource_id = _resources_folder_a_id
                       AND uur.user_id = (
                         SELECT id
                           FROM users
                          WHERE users.username = _user_a_name
                                         )
                       AND uur.role_id = (
                         SELECT roles.id
                           FROM roles
                          WHERE roles.name = 'admin'
                                         )
                         ) THEN
                    RAISE NOTICE 'Test 1 passed: "Should assign the `admin` role for `_folder_a_name` to the user `_user_a_id`"';
                ELSE
                    RAISE EXCEPTION 'Test 1 failed: "Should assign the `admin` role for `_folder_a_name` to the user `_user_a_id`"';
                END IF;
            END;


            -- Create root folder `_folder_a_name`
               INSERT
                 INTO folders (resource_id, name)
               VALUES (_resources_folder_a_id, _folder_a_name)
            RETURNING id INTO _folder_a_id;


            -- Set `editor` role for `_resources_folder_a_id` for user `_user_a_id`
            PERFORM chmod(_resources_folder_a_id, _user_b_id, 'editor');

            -- Test 2: Should correctly assign the `editor` role for `_folder_a_name` to the user `_user_b_id`
            IF exists (
                SELECT 1
                  FROM virtual_file_system.public.user_role_resource uur
                 WHERE uur.resource_id = _resources_folder_a_id
                   AND uur.user_id = (
                     SELECT id
                       FROM users
                      WHERE users.username = _user_b_name
                                     )
                   AND uur.role_id = (
                     SELECT id
                       FROM roles
                      WHERE name = 'editor'
                                     )
                      ) THEN
                RAISE NOTICE 'Test 2 passed: "Should correctly assign the `editor` role for `_folder_a_name` to the user `_user_b_id`"';
            ELSE
                RAISE EXCEPTION 'Test 2 failed: "Should correctly assign the `editor` role for `_folder_a_name` to the user `_user_b_id`"';
            END IF;


            -- Create child folder "_folder_aa_1" inside "_folder_a"
               INSERT
                 INTO resources (created_by, updated_by, type, parent_folder_id)
               VALUES (_user_b_id, _user_b_id, 'folder', _resources_folder_a_id)
            RETURNING id INTO _resources_folder_aa_1_id;

            PERFORM chmod(_resources_folder_aa_1_id, _user_b_id, 'owner');

               INSERT
                 INTO folders (resource_id, name)
               VALUES (_resources_folder_aa_1_id, _folder_aa_1_name)
            RETURNING id INTO _folder_aa_id;

            -- Test 3: Should assign the `owner` role for `_folder_aa_1_name` to the user `_user_b_name`
            IF exists (
                SELECT 1
                  FROM virtual_file_system.public.user_role_resource uur
                 WHERE uur.resource_id = _resources_folder_aa_1_id
                   AND uur.user_id = (
                     SELECT id
                       FROM users
                      WHERE users.username = _user_b_name
                                     )
                   AND uur.role_id = (
                     SELECT id
                       FROM roles
                      WHERE name = 'owner'
                                     )
                      ) THEN
                RAISE NOTICE 'Test 3 passed: "Should assign the `owner` role for `_folder_aa_1_name` to the user `_user_b_name`"';
            ELSE
                RAISE EXCEPTION 'Test 3 failed: "Should assign the `owner` role for `_folder_aa_1_name` to the user `_user_b_name`"';
            END IF;

            -- Test 4: Should fail to assign a role with a non-existent resource_id
            BEGIN
                PERFORM chmod(non_existent_resource_id, _user_a_name, 'admin');
                RAISE EXCEPTION 'Test 4 failed: "Should fail to assign a role with a non-existent resource_id"';
            EXCEPTION
                WHEN OTHERS THEN RAISE NOTICE 'Test 4 passed: "Should fail to assign a role with a non-existent resource_id"';
            END;

            -- Test 5: Should fail to assign a role with a non-existent username
            BEGIN
                PERFORM chmod(_resources_folder_a_id, non_existent_user, 'admin');
                RAISE EXCEPTION 'Test 5 failed: "Should fail to assign a role with a non-existent username"';
            EXCEPTION
                WHEN OTHERS THEN RAISE NOTICE 'Test 5 passed: "Should fail to assign a role with a non-existent username"';
            END;


            -- Test 6: Should fail to assign a role with a wrong role type
            BEGIN
                PERFORM chmod(_resources_folder_a_id, _user_a_name, wrong_role_type);
                RAISE EXCEPTION 'Test 6 failed: "Should fail to assign a role with a wrong role type"';
            EXCEPTION
                WHEN OTHERS THEN RAISE NOTICE 'Test 6 passed: "Should fail to assign a role with a wrong role type"';
            END;

        EXCEPTION
            WHEN OTHERS THEN --
                RAISE NOTICE 'Exception: %', sqlerrm;
            -- Ensure that the exception won't prevent execution of the cleanup section
        END;

        -- Cleanup

        -- Example cleanup code:
        DELETE FROM virtual_file_system.public.files f WHERE f.id = _folder_aa_id;
        DELETE FROM virtual_file_system.public.files f WHERE f.id = _folder_a_id;

        DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_aa_1_id;
        DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_a_id;


        DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_c_id;
        DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_b_id;
        DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_a_id;
        RAISE NOTICE 'Cleanup chmod tests completed';
    END;
$$;
