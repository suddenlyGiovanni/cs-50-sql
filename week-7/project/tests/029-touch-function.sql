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
        _random_uuid                    UUID     := gen_random_uuid();
        _user_name                      VARCHAR  := 'test_user_' || _random_uuid;
        _user_email                     VARCHAR  := _user_name || '@test.com';
        _user_id                        INT;
        _invalid_user_id                INT      := (
                                                        SELECT floor(random() * (9999999 - 1000000 + 1) + 1000000)::INT
                                                    );
        _other_random_uuid              UUID     := gen_random_uuid();
        _other_user_name                VARCHAR  := 'test_user_' || _other_random_uuid;
        _other_user_email               VARCHAR  := _other_user_name || '@test.com';
        _other_user_id                  INT;

        -- resources:
        _resources_folder_id            INT;
        _invalid_resources_folder_id    INT      := (
                                                        SELECT floor(random() * (9999999 - 1000000 + 1) + 1000000)::INT
                                                    );
        _invalid_resources_file_id      INT;
        _same_name_resources_file_id    INT;
        _other_user_resources_folder_id INT;
        _resources_folder_b_id          INT;

        -- folders
        _folder_name                    VARCHAR  := 'test_folder_' || _random_uuid;
        _folder_id                      INT;
        _file_b_id                      INT;


        -- roles:
        _owner_role_id                  SMALLINT := (
                                                        SELECT id
                                                          FROM roles
                                                         WHERE name = 'owner'::ROLE
                                                    );

    BEGIN
        RAISE NOTICE 'Running `touch` tests';
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
            -- invalid parent_folder_id, e.g non existent folder
            -- invalid parent_folder_id type
            -- non unique file name
            -- invalid permissions


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

            -- Test 02: Should fail to create a file in a non-existent parent folder
            BEGIN
                PERFORM touch( --
                        _user_id, --
                        'wrong_type_parent_folder_test_file', --
                        'text/plain', --
                        _invalid_resources_folder_id, --
                        '/path/to/file', --
                        1024 --
                        );
                RAISE EXCEPTION 'Validation for wrong parent_folder_id failed to raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'Parent folder with id "%" does not exist' THEN
                    RAISE NOTICE 'Test 02 passed: "Should fail to create a File for a non-existent parent folder" - Expected exception: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 02 failed: "Should fail to create a File for a non-existent parent folder" - Unexpected exception: %', sqlerrm;
                END IF;
            END;

            -- Test 03: Should fail to create a file in a parent resource that is not a folder
            BEGIN
                -- create a file resource
                   INSERT
                     INTO resources (type, created_by, updated_by, parent_folder_id)
                   VALUES ('file', _user_id, _user_id, _resources_folder_id)
                RETURNING resources.id INTO _invalid_resources_file_id;

                PERFORM touch( --
                        _user_id, --
                        'non_existent_parent_folder_test_file', --
                        'text/plain', --
                        _invalid_resources_file_id, --
                        '/path/to/file', --
                        1024 --
                        );
                RAISE EXCEPTION 'Validation for wrong parent_folder_id failed to raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'Parent folder with id "%" does not exist' THEN
                    RAISE NOTICE 'Test 03 passed: "Should fail to create a File for a parent folder of wrong type" - Expected exception: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 03 failed: "Should fail to create a File for a parent folder of wrong type" - Unexpected exception: %', sqlerrm;
                END IF;
            END;

            -- Test 04: Should fail to crate a file when a file with the same name already exists in the parent folder
            BEGIN
                -- create a file resource
                   INSERT
                     INTO resources (type, created_by, updated_by, parent_folder_id)
                   VALUES ('file', _user_id, _user_id, _resources_folder_id)
                RETURNING resources.id INTO _same_name_resources_file_id;

                -- crate a file with an arbitrary name
                INSERT
                  INTO files (resource_id, name, mime_type, storage_path)
                VALUES (_same_name_resources_file_id, 'same_name_file.txt', 'text/plain', '/path/to/file');


                PERFORM touch( --
                        _user_id, --
                        'same_name_file.txt', --
                        'text/plain', --
                        _resources_folder_id, --
                        '/path/to/file', --
                        1024 --
                        );
                RAISE EXCEPTION 'Validation for unique file name failed to raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'File with name "%" already exists in the parent folder' THEN
                    RAISE NOTICE 'Test 04 passed: "Should fail to create a File for an already existing file resource with the same name" - Expected exception: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 04 failed: "Should fail to create a File for an already existing file resource with the same name" - Unexpected exception: %', sqlerrm;
                END IF;
            END;


            -- Test 05: Should fail to crate a file when the user has no write permission on the parent_folder_id
            BEGIN
                /**
                  ARRANGE: Create a new folder structure for which the user has no write permission
                    _resources_folder_id (owned by _user_id - _other_user has editor role)
                    ├── _other_user_resources_folder_id (owned by _other_user_id)
                 */
                   INSERT
                     INTO users (username, email, hashed_password)
                   VALUES (_other_user_name, _other_user_email, _other_random_uuid)
                RETURNING users.id INTO _other_user_id;

                INSERT
                  INTO user_role_resource (resource_id, user_id, role_id)
                VALUES (_resources_folder_id, _other_user_id, (
                    SELECT id
                      FROM roles
                     WHERE name = 'editor'::ROLE
                                                              ))
                    ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;

                   INSERT
                     INTO resources (type, created_by, updated_by, parent_folder_id)
                   VALUES ('folder', _other_user_id, _other_user_id, _resources_folder_id)
                RETURNING resources.id INTO _other_user_resources_folder_id;

                INSERT
                  INTO folders (resource_id, name)
                VALUES (_other_user_resources_folder_id, 'other_owner_' || 'test_folder_' || _other_random_uuid);

                -- Act
                PERFORM touch( --
                        _user_id, --
                        'should_fail_file_since_user_has_no_write_permission_for_containing_folder.txt', --
                        'text/plain', --
                        _other_user_resources_folder_id, --
                        '/path/to/file', --
                        1024 --
                        );

                -- Assert
                RAISE EXCEPTION 'Validation for write permission failed to raise exception';
            EXCEPTION
                WHEN OTHERS THEN IF sqlerrm LIKE 'User "%" does not have write permission on the parent folder' THEN
                    RAISE NOTICE 'Test 05 passed: "Should fail to crate a file when the user has no write permission on the parent_folder_id" - Expected exception: %',sqlerrm;
                ELSE
                    RAISE NOTICE 'Test 05 failed: "Should fail to crate a file when the user has no write permission on the parent_folder_id" - Unexpected exception: %', sqlerrm;
                END IF;

            END;

            -- Test 0?: Should assign to the file resource the same access role as its parent folder resource
            BEGIN
                --  Arrange
                --  create a new test folder
                   INSERT
                     INTO resources (type, created_by, updated_by, parent_folder_id)
                   VALUES ('folder', _user_id, _user_id, _resources_folder_id)
                RETURNING resources.id INTO _resources_folder_b_id;

                INSERT
                  INTO folders (resource_id, name) VALUES (_resources_folder_b_id, 'test_folder_b_' || _random_uuid);

                -- assign to the parent folder a specific role, different from the default one
                INSERT
                  INTO user_role_resource (resource_id, user_id, role_id)
                VALUES (_resources_folder_b_id, _user_id, (
                    SELECT id
                      FROM roles
                     WHERE name = 'editor'::ROLE
                                                          ))
                    ON CONFLICT (resource_id, user_id) DO UPDATE SET role_id = excluded.role_id;

                -- Act
                SELECT touch( --
                               _user_id, --
                               'file_with_same_role_as_parent_folder.txt', --
                               'text/plain', --
                               _resources_folder_b_id, --
                               '/path/to/file', --
                               1024 --
                       )
                  INTO _file_b_id;
                -- Assert
                -- check if the file resource has the same role as the parent folder

                IF NOT exists (
                    SELECT 1
                      FROM user_role_resource urr
                     WHERE urr.resource_id = (
                         SELECT f.resource_id
                           FROM files f
                          WHERE id = _file_b_id
                                             )
                       AND urr.user_id = _user_id
                       AND urr.role_id = (
                         SELECT role_id FROM user_role_resource urr2 WHERE urr2.resource_id = _resources_folder_b_id
                            AND urr2.user_id = _user_id
                                         )
                              ) THEN
                    RAISE EXCEPTION 'Test 0? failed: "Should assign to the file resource the same access role as its parent folder resource"';
                ELSE
                    RAISE NOTICE 'Test 0? passed: "Should assign to the file resource the same access role as its parent folder resource"';
                END IF;

            END;


        EXCEPTION
            WHEN OTHERS THEN --
                RAISE NOTICE 'Exception: %', sqlerrm;
            -- Ensure that the exception won't prevent execution of the cleanup section
        END;

        -- Tear down: Cleanup test data
        BEGIN
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _other_user_resources_folder_id;
            DELETE FROM virtual_file_system.public.users u WHERE u.id = _other_user_id;
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _same_name_resources_file_id;
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _invalid_resources_file_id;
            DELETE FROM virtual_file_system.public.files f WHERE f.id = _folder_id;
            DELETE FROM virtual_file_system.public.resources r WHERE r.id = _resources_folder_id;
            DELETE FROM virtual_file_system.public.users u WHERE u.id = _user_id;
            RAISE NOTICE 'Cleanup `touch` test data completed';
        EXCEPTION
            WHEN OTHERS THEN RAISE NOTICE 'Cleanup failed: %', sqlerrm;
        END;
    END;
$$;
