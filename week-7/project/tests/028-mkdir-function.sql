SET search_path TO virtual_file_system, public;


/*
*  Unit test for mkdir function:
 * Should be able to create the following folder structure:
 *
 * _folder_a
 * ├── _folder_aa_1
 * │   └── _folder_aaa_1
 * │       └── _folder_aaaa_1
 * └── _folder_aa_2
* _folder_b
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

        -- folders
        _folder_a                   VARCHAR := 'test_folder_' || _random_uuid || '_a';
        _folder_aa_1                VARCHAR := 'test_folder_' || _random_uuid || '_aa_1';

        -- Additional folders for testing
        _resources_folder_b_id      INT;
        _resources_folder_null_id   INT;
        _resources_folder_broken_id INT;
        _folder_b                   VARCHAR := 'test_folder_' || _random_uuid || '_b';
        non_existent_user           VARCHAR := 'non_existent_user_' || _random_uuid;
        non_existent_role           VARCHAR := 'non_existent_role';

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
                   mkdir(_folder_a, _user_id, 'owner'::ROLE, NULL);

            -- Assert:
            -- Test 1: Should be able to create a top-level folder resource `_folder_a` with mkdir function
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
                    RAISE NOTICE 'Test 01 passed: "Should be able to create a top-level folder `_folder_a` with mkdir function"';
                ELSE
                    RAISE EXCEPTION 'Test 01 failed: "Should be able to create a top-level folder `_folder_a` with mkdir function';
                END IF;
            END;

            -- Test 2: Should be able to create a top-level folder `_folder_a` with mkdir function
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.folders f
                     WHERE f.resource_id = _resources_folder_a_id AND f.name = _folder_a
                         ) THEN
                    RAISE NOTICE 'Test 02 passed: "Should be able to create a top-level folder `_folder_a` with mkdir function"';
                ELSE
                    RAISE EXCEPTION 'Test 02 failed: "Should be able to create a top-level folder `_folder_a` with mkdir function"';
                END IF;
            END;

            -- Test 3: Should be able to create the correct resource/role association for the `_folder_a` with mkdir function
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
                    RAISE NOTICE 'Test 03 passed: "Should be able to create the correct resource/role association for the `_folder_a` with mkdir function"';
                ELSE
                    RAISE EXCEPTION 'Test 03 failed: "Should be able to create the correct resource/role association for the `_folder_a` with mkdir function"';
                END IF;
            END;


            -- Act: Create sub-folder "_folder_aa_1" under folder "_folder_a"
            SELECT INTO _resources_folder_aa_1_id
                   mkdir(_folder_aa_1, _user_id, 'admin'::ROLE, _resources_folder_a_id);

            -- Assert:
            -- Test 4: Should be able to create a `_folder_aa_1` folder resource in the `_folder_a` folder with mkdir function
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
                    RAISE NOTICE 'Test 04 passed: "Should be able to create a `_folder_aa_1` folder resource in the `_folder_a` folder with mkdir function"';
                ELSE
                    RAISE EXCEPTION 'Test 04 failed: "Should be able to create a `_folder_aa_1` folder resource in the `_folder_a` folder with mkdir function"';
                END IF;
            END;

            -- Test 5: Should be able to create a `_folder_aa_1` folder with mkdir function
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.folders f
                     WHERE f.resource_id = _resources_folder_aa_1_id
                       AND f.name = _folder_aa_1
                         ) THEN
                    RAISE NOTICE 'Test 05 passed: "Should be able to create a `_folder_aa_1` folder with mkdir function"';
                ELSE
                    RAISE EXCEPTION 'Test 05 failed: "Should be able to create a `_folder_aa_1` folder with mkdir function"';
                END IF;
            END;

            -- Test 6: Should be able to create the correct resource/role association for the `_folder_aa_1` with mkdir function
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.user_role_resource uur
                     WHERE uur.resource_id = _resources_folder_aa_1_id
                       AND uur.user_id = _user_id
                       AND uur.role_id = (
                         SELECT roles.id
                           FROM roles
                          WHERE roles.name = 'admin'::ROLE
                                         )
                         ) THEN
                    RAISE NOTICE 'Test 06 passed: "Should be able to create the correct resource/role association for the `_folder_aa_1` with mkdir function"';
                ELSE
                    RAISE EXCEPTION 'Test 06 failed: "Should be able to create the correct resource/role association for the `_folder_aa_1` with mkdir function"';
                END IF;
            END;


            -- Act: Create folder "_folder_b" with a different role type
            SELECT INTO _resources_folder_b_id
                   mkdir(_folder_b, _user_id, 'editor'::ROLE, NULL);


            -- Test 7: Should be able to create a `_folder_b` as top level folder resource with `editor` role with mkdir function
            IF exists(
                SELECT 1
                  FROM virtual_file_system.public.user_role_resource uur
                 WHERE uur.resource_id = _resources_folder_b_id
                   AND uur.user_id = _user_id
                   AND uur.role_id = (
                     SELECT roles.id
                       FROM roles
                      WHERE roles.name = 'editor'::ROLE
                                     )
                     ) THEN
                RAISE NOTICE 'Test 07 passed: "Should be able to create a `_folder_b` as top level folder resource with `editor` role with mkdir function"';
            ELSE
                RAISE EXCEPTION 'Test 07 failed: "Should be able to create a `_folder_b` as top level folder resource with `editor` role with mkdir function"';
            END IF;


            -- Test 8: Should fail to create a folder with NULL name
            BEGIN
                SELECT INTO _resources_folder_null_id
                       mkdir(NULL, _user_id, 'owner'::ROLE, NULL);
                RAISE EXCEPTION 'Validation for NULL folder name  failed to raise an exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm = 'Folder name cannot be null or empty string' THEN
                    RAISE NOTICE 'Test 08 passed: "Should fail to create a folder with NULL name" - Expected exception: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 08 failed: "Should fail to create a folder with NULL name"- Unexpected exception: %"', sqlerrm;
                END IF;
            END;


            -- Test 9: Should fail to create a folder with non-existent parent folder ID
            BEGIN
                SELECT INTO _resources_folder_broken_id
                       mkdir(_folder_a, _user_id, 'owner'::ROLE, -1);
                RAISE EXCEPTION 'Validation for non-existent parent folder ID failed to raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm = 'Parent folder with id "-1" does not exist' THEN
                    RAISE NOTICE 'Test 09 passed: "Should fail to create a folder with non-existent parent folder ID" - Expected exception: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 09 failed: "Should fail to create a folder with non-existent parent folder ID" - Unexpected exception: %"', sqlerrm;
                END IF;
            END;

            -- Test 10: Should fail to create a duplicate folder `_folder_a` in the same parent folder
            BEGIN
                PERFORM mkdir(_folder_a, _user_id, 'owner'::ROLE, NULL);
                RAISE EXCEPTION 'Validation for duplicate folder name failed to raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'Folder with name "%" already exists as a root resource' THEN
                    RAISE NOTICE 'Test 10 passed: "Should fail to create a duplicate folder `_folder_a` in the same parent folder" - Expected exception: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 10 failed: "Should fail to create a duplicate folder `_folder_a` in the same parent folder" - Unexpected exception: %', sqlerrm;
                END IF;
            END;

            -- Test 11: Should fail to create a folder for a non-existent user
            BEGIN
                PERFORM mkdir(_folder_a, -1, 'owner'::ROLE, NULL);
                RAISE EXCEPTION 'Validation for non-existent user failed to raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'User "%" does not exist' THEN
                    RAISE NOTICE 'Test 11 passed: "Should fail to create a folder for a non-existent user" - Expected exception: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 11 failed: "Should fail to create a folder for a non-existent user" - Unexpected exception: %', sqlerrm;
                END IF;
            END;


            -- Test 12: Should fail to create a folder for a non-existent role
            BEGIN
                PERFORM mkdir(_folder_a, _user_id, 'master_of_the_universe', NULL);
                RAISE EXCEPTION 'Validation for non-existent role failed to raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'invalid input value for enum role: %"' THEN
                    RAISE NOTICE 'Test 12 passed: "Should fail to create a folder for a non-existent role" - Expected exception: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 12 failed: "Should fail to create a folder for a non-existent role" - Unexpected exception: %', sqlerrm;
                END IF;
            END;


        EXCEPTION
            WHEN OTHERS THEN --
                RAISE NOTICE 'Exception: %', sqlerrm;
            -- Ensure that the exception won't prevent execution of the cleanup section
        END;

        -- Tear down: Cleanup test data
        BEGIN
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_broken_id;
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_null_id;
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_b_id;
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_aa_1_id;
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_a_id;
            DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_id;
            RAISE NOTICE 'Cleanup `mkdir` test data completed';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Cleanup failed: %', sqlerrm;
        END;
    END;
$$;
