/*
 * Unit test for files_validate_name_uniqueness trigger:
 * Should validate folder name uniqueness within the same folder level.
 */
DO
$$
    DECLARE
        -- Users
        _random_uuid              UUID    := gen_random_uuid();
        _user_name                VARCHAR := 'test_user_' || _random_uuid;
        _user_email               VARCHAR := _user_name || '@test.com';
        _user_id                  INT;

        -- Resources
        _resources_folder_root_id INT;
        _resources_file_a_id      INT;
        _resources_file_a_dup_id  INT;

        -- Folders
        _folder_root_id           INT;
        _folder_root_name         VARCHAR := 'test_folder_' || _random_uuid || '_root' ;
        _folder_name_like_uuid    VARCHAR := 'test_folder_' || _random_uuid || '_%';


        -- Files
        _file_a_name              VARCHAR := 'test_file_' || _random_uuid || '_a';
        _file_a_dup_name          VARCHAR := _file_a_name;
        _file_a_id                INT;
        _file_a_dup_id            INT;
        _mime_type                VARCHAR := 'application/json';


    BEGIN
        RAISE NOTICE 'Running `files_validate_name_uniqueness` tests';
        -- Outer block to handle exceptions and ensure cleanup
        BEGIN
            -- Arrange: Create a test user
               INSERT
                 INTO users (username, email, hashed_password)
               VALUES (_user_name, _user_email, _random_uuid)
            RETURNING id INTO _user_id;

            -- Create a parent folder resource
               INSERT
                 INTO resources (created_by, updated_by, type, parent_folder_id)
               VALUES (_user_id, _user_id, 'folder', NULL)
            RETURNING id INTO _resources_folder_root_id;

            INSERT
              INTO user_role_resource (user_id, role_id, resource_id)
            VALUES (_user_id, (
                SELECT roles.id
                  FROM roles
                 WHERE roles.name = 'admin'
                              ), _resources_folder_root_id);

               INSERT
                 INTO folders (resource_id, name)
               VALUES (_resources_folder_root_id, _folder_root_name)
            RETURNING id INTO _folder_root_id;


            -- insert a file in _folder_root_id

               INSERT
                 INTO resources (created_by, updated_by, type, parent_folder_id)
               VALUES (_user_id, _user_id, 'file', _resources_folder_root_id)
            RETURNING id INTO _resources_file_a_id;

               INSERT
                 INTO files (resource_id, name, mime_type, storage_path)
               VALUES (_resources_file_a_id, _file_a_name, _mime_type, '/' || _file_a_name || '.json')
            RETURNING id INTO _file_a_id;

            -- Test 1: Attempt to insert duplicate "_file_a_name" inside "_folder_root"
            BEGIN
                -- Create another resource
                   INSERT
                     INTO resources (created_by, updated_by, type, parent_folder_id)
                   VALUES (_user_id, _user_id, 'file', _resources_folder_root_id)
                RETURNING id INTO _resources_file_a_dup_id;

                -- Insert the folder entry with the duplicate name
                   INSERT
                     INTO files (resource_id, name, mime_type, storage_path)
                   VALUES (_resources_file_a_dup_id, _file_a_dup_name, _mime_type, '/' || _file_a_dup_name || '.json')
                RETURNING id INTO _file_a_dup_id;
                RAISE EXCEPTION 'Validation for duplicate file name did not raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'File with name "%" already exists in the parent folder id "%"' THEN
                    RAISE NOTICE 'Test 1 passed: "Validation for duplicate file name raised correct exception"- Error message: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 1 failed: "Validation for duplicate file name raised unexpected exception: %"', sqlerrm;
                END IF;
            END;


        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Unit test failed: %', sqlerrm;
        END;

        -- Tear down: Cleanup test data
        BEGIN
            DELETE FROM folders WHERE name LIKE _folder_name_like_uuid;
            DELETE FROM files WHERE id IN (_file_a_id, _file_a_dup_id);
            DELETE FROM resources WHERE created_by = _user_id;
            DELETE FROM users WHERE id = _user_id;
            RAISE NOTICE 'Cleanup `files_validate_name_uniqueness` test data completed';

        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Cleanup failed: %', sqlerrm;
        END;
    END;
$$;
