/*
*  Unit test for mkdir function:
 * Should be able to create the following folder structure:
 *
 * _folder_a
 * ├── _folder_aa_1
 * │   └── _folder_aaa_1
 * │       └── _folder_aaaa_1
 * └── _folder_aa_2
*/
DO
$$
    DECLARE
        -- users:
        _random_uuid                UUID    := gen_random_uuid();
        _user_name                  VARCHAR := 'test_user_' || _random_uuid;
        _user_email                 VARCHAR := _user_name || '@test.com';
        _user_id                    INT;

        -- resources:
        _resources_folder_a_id      INT;
        _resources_folder_aa_1_id   INT;
        _resources_folder_aa_2_id   INT;
        _resources_folder_aaa_1_id  INT;
        _resources_folder_aaaa_1_id INT;


        -- folders
        _folder_a                   VARCHAR := 'test_folder_' || _random_uuid || '_a';
        _folder_aa_1                VARCHAR := 'test_folder_' || _random_uuid || '_aa_1';
        _folder_aa_2                VARCHAR := 'test_folder_' || _random_uuid || '_aa_2';
        _folder_aaa_1               VARCHAR := 'test_folder_' || _random_uuid || '_aaa_1';
        _folder_aaaa_1              VARCHAR := 'test_folder_' || _random_uuid || '_aaaa_1';

    BEGIN
        -- Outer block to handle exceptions and ensure cleanup
        BEGIN
            -- Arrange: Create a test user
               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_name, _user_email, _random_uuid)
            RETURNING id INTO _user_id;


            -- Act: Create folder "_folder_a"
            SELECT INTO _resources_folder_a_id
                   mkdir(_folder_a, _user_name, 'owner'::ROLE_TYPE, NULL);

            -- Assert:
            -- Test 1: Check if resource for "_folder_a" was created successfully
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.resources r
                     WHERE r.id = _resources_folder_a_id
                       AND r.created_by = _user_id
                       AND r.updated_by = _user_id
                       AND r.type = 'folder'
                       AND r.parent_folder_id IS NULL
                         ) THEN
                    RAISE NOTICE 'Test 1 passed "Check if resource for `_folder_a` was created successfully"';
                ELSE
                    RAISE EXCEPTION 'Test 1 failed "Check if resource for `_folder_a` was created successfully"';
                END IF;
            END;

            -- Test 2: Check if folder "_folder_a" was created successfully
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.folders f
                     WHERE f.resource_id = _resources_folder_a_id AND f.name = _folder_a
                         ) THEN
                    RAISE NOTICE 'Test 2 passed "Check if folder `_folder_a` was created successfully"';
                ELSE
                    RAISE EXCEPTION 'Test 2 failed "Check if folder `_folder_a` was created successfully"';
                END IF;
            END;

            -- Test 3: Check if the resource "_folder_a" has the correct role associated
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.user_role_resource uur
                     WHERE uur.resource_id = _resources_folder_a_id
                       AND uur.user_id = _user_id
                       AND uur.role_id = (
                         SELECT roles.id
                           FROM roles
                          WHERE roles.name = 'owner'
                                         )
                         ) THEN
                    RAISE NOTICE 'Test 3 passed "Check if the resource `_folder_a` has the correct role associated"';
                ELSE
                    RAISE EXCEPTION 'Test 3 failed "Check if the resource `_folder_a` has the correct role associated"';
                END IF;
            END;


            -- Act: Create sub-folder "_folder_aa_1" under folder "_folder_a"
            SELECT INTO _resources_folder_aa_1_id
                   mkdir(_folder_aa_1, _user_name, 'admin'::ROLE_TYPE, _resources_folder_a_id);

            -- Assert:
            -- Test 4: Check if resource for "_folder_aa_1" was created successfully
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.resources r
                     WHERE r.id = _resources_folder_aa_1_id
                       AND r.created_by = _user_id
                       AND r.updated_by = _user_id
                       AND r.type = 'folder'
                       AND r.parent_folder_id = _resources_folder_a_id
                         ) THEN
                    RAISE NOTICE 'Test 4 passed "Check if resource for `_folder_aa_1` was created successfully"';
                ELSE
                    RAISE EXCEPTION 'Test 4 failed "Check if resource for `_folder_aa_1` was created successfully"';
                END IF;
            END;

            -- Test 5: Check if folder "_folder_aa_1" was created successfully
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.folders f
                     WHERE f.resource_id = _resources_folder_aa_1_id
                       AND f.name = _folder_aa_1
                         ) THEN
                    RAISE NOTICE 'Test 5 passed "Check if folder `_folder_aa_1` was created successfully"';
                ELSE
                    RAISE EXCEPTION 'Test 5 failed "Check if folder `_folder_aa_1` was created successfully"';
                END IF;
            END;

            -- Test 6: Check if the resource "_folder_a" has the correct role associated
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.user_role_resource uur
                     WHERE uur.resource_id = _resources_folder_aa_1_id
                       AND uur.user_id = _user_id
                       AND uur.role_id = (
                         SELECT roles.id
                           FROM roles
                          WHERE roles.name = 'admin'
                                         )
                         ) THEN
                    RAISE NOTICE 'Test 6 passed "Check if the resource `_folder_a` has the correct role associated"';
                ELSE
                    RAISE EXCEPTION 'Test 6 failed "Check if the resource `_folder_a` has the correct role associated"';
                END IF;
            END;


            -- Act: Create sub-folder "_folder_aa_2" under folder "_folder_a"
            SELECT INTO _resources_folder_aa_2_id
                   mkdir(_folder_aa_2, _user_name, 'editor'::ROLE_TYPE, _resources_folder_a_id);

            -- Assert: Check if resource for "_folder_aa_2" was created successfully with the role "editor"
            IF exists(
                SELECT 1
                  FROM virtual_file_system.public.user_role_resource uur
                 WHERE uur.resource_id = _resources_folder_aa_2_id
                   AND uur.user_id = _user_id
                   AND uur.role_id = (
                     SELECT roles.id
                       FROM roles
                      WHERE roles.name = 'editor'
                                     )
                     ) THEN
                RAISE NOTICE 'Test 7 passed "Check if resource for `_folder_aa_2` was created successfully with the role editor"';
            ELSE
                RAISE EXCEPTION 'Test 8 failed "Check if resource for `_folder_aa_2` was created successfully with the role editor"';
            END IF;

            -- Assert:
            -- Test 5: Check if resource for "_folder_aa_2" was created successfully
            -- Test 6: Check if folder "_folder_aa_2" was created successfully

            -- Act: Create sub-folder "_folder_aaa_1" under folder "_folder_aa_1"
            -- SELECT INTO _resources_folder_aaa_1_id
            --        mkdir(_folder_aaa_1, _user_name, parent_folder_id => _resources_folder_aa_1_id);

            -- Assert:
            -- Test 7: Check if resource for "_folder_aaa_1" was created successfully
            -- Test 8: Check if folder "_folder_aaa_1" was created successfully

            -- Act: Create sub-folder "_folder_aaaa_1" under folder "_folder_aaa_1"
            -- SELECT INTO _resources_folder_aaaa_1_id
            --        mkdir(_folder_aaaa_1, _user_name, parent_folder_id => _resources_folder_aaa_1_id);

            -- Assert:
            -- Test 9: Check if resource for "_folder_aaaa_1" was created successfully
            -- Test 10: Check if folder "_folder_aaaa_1" was created successfully


        EXCEPTION
            WHEN OTHERS THEN --
                RAISE NOTICE 'Exception: %', sqlerrm;
                -- Ensure that the exception won't prevent execution of the cleanup section


                -- Cleanup
                BEGIN
                    -- Example cleanup code:
                    DELETE
                      FROM virtual_file_system.public.folders f
                     WHERE f.resource_id IN (
                         -- _resources_folder_aaaa_1_id,
                         -- _resources_folder_aaa_1_id,
                                             _resources_folder_aa_2_id,
                                             _resources_folder_aa_1_id,
                                             _resources_folder_a_id);
                    DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_id;
                    RAISE NOTICE 'Cleanup completed';
                END;
        END;
    END;
$$;
