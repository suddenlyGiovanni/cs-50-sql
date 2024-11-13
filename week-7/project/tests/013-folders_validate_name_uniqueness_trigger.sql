/*
 * Unit test for folders_validate_name_uniqueness trigger:
 * Should validate folder name uniqueness within the same folder level.
 */
DO
$$
    DECLARE
        -- Users
        _random_uuid                UUID    := gen_random_uuid();
        _user_name                  VARCHAR := 'test_user_' || _random_uuid;
        _user_email                 VARCHAR := _user_name || '@test.com';
        _user_id                    INT;

        -- Resources
        _resources_folder_a_id      INT;
        _resources_folder_bb_dup_id INT;
        _resources_folder_aa_1_id   INT;
        _resources_folder_aa_2_id   INT;
        _resources_folder_aa_3_id   INT;
        _resources_folder_aa_4_id   INT;
        _resources_folder_aa_dup_id INT;

        -- Folders
        _folder_a_id                INT;
        _folder_a_name              VARCHAR := 'test_folder_' || _random_uuid || '_a';
        --
        _folder_b_id                INT;
        _folder_a_name_dup          VARCHAR := _folder_a_name;
        --
        _folder_aa_id               INT;
        _folder_aa_1_name           VARCHAR := 'test_folder_' || _random_uuid || '_aa_1';
        --
        _folder_aa_duplicate_id     INT;
        _folder_aa_name_duplicate   VARCHAR := _folder_aa_1_name;
        --
        _folder_aa_2_name           VARCHAR := 'test_folder_' || _random_uuid || '_aa_2';

        -- Test names
        _folder_aa_3_id             INT;
        _folder_aa_4_id             INT;
        _empty_name                 VARCHAR := '   ';
        _non_trimmed_name           VARCHAR := '      valid_name      ';

        -- clean up folder name
        _folder_name_like_uuid      VARCHAR := 'test_folder_' || _random_uuid || '_%';


    BEGIN
        -- Outer block to handle exceptions and ensure cleanup
        BEGIN
            -- Arrange: Create a test user
               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_name, _user_email, _random_uuid)
            RETURNING id INTO _user_id;

            -- Create a parent folder resource
               INSERT
                 INTO resources (created_by, updated_by, type)
               VALUES (_user_id, _user_id, 'folder')
            RETURNING id INTO _resources_folder_a_id;

               INSERT
                 INTO folders (resource_id, name)
               VALUES (_resources_folder_a_id, _folder_a_name)
            RETURNING id INTO _folder_a_id;

            -- Act & Assert: Create child folder "_folder_aa_1" inside "_folder_a"
            -- Create the resource
               INSERT
                 INTO resources (created_by, updated_by, type, parent_folder_id)
               VALUES (_user_id, _user_id, 'folder', _resources_folder_a_id)
            RETURNING id INTO _resources_folder_aa_1_id;

            -- Insert the folder entry
               INSERT
                 INTO folders (resource_id, name)
               VALUES (_resources_folder_aa_1_id, _folder_aa_1_name)
            RETURNING id INTO _folder_aa_id;


            -- Test 1: Check if folder "_folder_aa_1" creation was successful
            BEGIN
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.folders       f
                          JOIN virtual_file_system.public.resources r ON f.resource_id = r.id
                     WHERE f.name = _folder_aa_1_name
                       AND r.parent_folder_id = _resources_folder_a_id
                         ) THEN
                    RAISE NOTICE 'Test 1 passed: "Check if `_folder_aa_1` was created successfully in `_folder_a`"';
                ELSE
                    RAISE EXCEPTION 'Test 1 failed: "Check if `_folder_aa_1` was created successfully in `_folder_a`"';
                END IF;
            END;

            -- Test 2: Attempt to insert duplicate "_folder_aa_1" inside "_folder_a"
            BEGIN
                -- Create another resource
                   INSERT
                     INTO resources (created_by, updated_by, type, parent_folder_id)
                   VALUES (_user_id, _user_id, 'folder', _resources_folder_a_id)
                RETURNING id INTO _resources_folder_aa_dup_id;

                -- Insert the folder entry with the duplicate name
                   INSERT
                     INTO folders (resource_id, name)
                   VALUES (_resources_folder_aa_dup_id, _folder_aa_name_duplicate)
                RETURNING id INTO _folder_aa_duplicate_id;
                RAISE EXCEPTION 'Validation for duplicate folder name did not raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE '%already exists in the parent folder' THEN
                    RAISE NOTICE 'Test 2 passed: "Validation for duplicate folder name raised correct exception"- Error message: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 2 failed: "Validation for duplicate folder name raised unexpected exception: %"', sqlerrm;
                END IF;
            END;

            -- Test 3: Insert another unique folder "_folder_aa_2" inside "_folder_a"
            BEGIN
                -- Create another resource
                   INSERT
                     INTO resources (created_by, updated_by, type, parent_folder_id)
                   VALUES (_user_id, _user_id, 'folder', _resources_folder_a_id)
                RETURNING id INTO _resources_folder_aa_2_id;

                -- Insert the folder entry
                INSERT
                  INTO folders (resource_id, name) VALUES (_resources_folder_aa_2_id, _folder_aa_2_name);

                -- Assert
                IF exists(
                    SELECT 1
                      FROM virtual_file_system.public.folders       f
                          JOIN virtual_file_system.public.resources r ON f.resource_id = r.id
                     WHERE f.name = _folder_aa_2_name
                       AND r.parent_folder_id = _resources_folder_a_id
                         ) THEN
                    RAISE NOTICE 'Test 3 passed: "Check if `_folder_aa_2` was created successfully in `_folder_a`"';
                ELSE
                    RAISE EXCEPTION 'Test 3 failed: "Check if `_folder_aa_2` was created successfully in `_folder_a`"';
                END IF;
            END;


            -- Test 4: Attempt to insert duplicate top-level folder "_folder_b"
            BEGIN
                -- Create top-level folder resource
                   INSERT
                     INTO resources (created_by, updated_by, type, parent_folder_id)
                   VALUES (_user_id, _user_id, 'folder', NULL)
                RETURNING id INTO _resources_folder_bb_dup_id;

                -- Insert the top-level folder entry with the duplicate name
                   INSERT
                     INTO folders (resource_id, name)
                   VALUES (_resources_folder_bb_dup_id, _folder_a_name_dup)
                RETURNING id INTO _folder_b_id;
                RAISE EXCEPTION 'Validation for duplicate top-level folder name did not raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE '%already exists as a root resource' THEN
                    RAISE NOTICE 'Test 4 passed: "Validation for duplicate top-level folder name raised correct exception" - Error Message: %', sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 4 failed: "Validation for duplicate top-level folder name raised unexpected exception: %"', sqlerrm;
                END IF;
            END;


            -- Test 5: Attempt to insert a folder with an empty name
            BEGIN
                -- Create another resource
                   INSERT
                     INTO resources (created_by, updated_by, type, parent_folder_id)
                   VALUES (_user_id, _user_id, 'folder', _resources_folder_a_id)
                RETURNING id INTO _resources_folder_aa_3_id;

                -- Insert the folder entry with an empty name
                   INSERT
                     INTO folders (resource_id, name)
                   VALUES (_resources_folder_aa_3_id, _empty_name)
                RETURNING id INTO _folder_aa_3_id;
            EXCEPTION
                WHEN check_violation THEN RAISE NOTICE 'Test 5 passed: "Insertion of folder with empty name was prevented"';
                WHEN OTHERS THEN RAISE EXCEPTION 'Test 5 failed: "Unexpected error when attempting to insert folder with empty name"';
            END;

        EXCEPTION
            WHEN OTHERS THEN RAISE EXCEPTION 'Unit test failed: %', sqlerrm;
        END;

        -- Tear down: Cleanup test data
        DELETE FROM folders WHERE name LIKE _folder_name_like_uuid;
        DELETE FROM resources WHERE created_by = _user_id;
        DELETE FROM users WHERE id = _user_id;

    END;
$$;