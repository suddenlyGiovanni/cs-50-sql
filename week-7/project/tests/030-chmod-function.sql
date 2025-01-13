SET search_path TO virtual_file_system, public;

BEGIN;
/*
*  Unit test for chmod function:
*/
DO
$$
    DECLARE
        _random_admin_uuid         UUID := gen_random_uuid();
        _admin_id                  INTEGER;
        _random_b_uuid             UUID := gen_random_uuid();
        _user_b_id                 INTEGER;
        _random_c_uuid             UUID := gen_random_uuid();
        _user_c_id                 INTEGER;

        -- Folders
        _root_resource_id          INTEGER;
        _nested_folder_resource_id INTEGER;

    BEGIN
        RAISE NOTICE 'Running chmod tests';
        -- Outer block to handle exceptions and ensure cleanup
        BEGIN

            -- BEFORE ALL -> Arrange: Create a test user
               INSERT
                 INTO users (username, email, hashed_password)
               VALUES ( 'test_user_a_' || _random_admin_uuid --
                      , 'test_user_a_' || _random_admin_uuid || '@test.com' --
                      , _random_admin_uuid --
                      )
            RETURNING id
                INTO _admin_id;

               INSERT
                 INTO users (username, email, hashed_password)
               VALUES ( 'test_user_b_' || _random_b_uuid --
                      , 'test_user_b_' || _random_b_uuid || '@test.com' --
                      , _random_b_uuid --
                      )
            RETURNING id
                INTO _user_b_id;


               INSERT
                 INTO users (username, email, hashed_password)
               VALUES ( 'test_user_c_' || _random_c_uuid --
                      , 'test_user_c_' || _random_c_uuid || '@test.com' --
                      , _random_c_uuid --
                      )
            RETURNING id
                INTO _user_c_id;


            -- Create a parent folder resource
               INSERT
                 INTO resources (created_by, updated_by, type, parent_folder_id)
               VALUES (_admin_id, _admin_id, 'folder'::RESOURCE, NULL)
            RETURNING id INTO _root_resource_id;

            -- Create root folder `_folder_a_name`
            INSERT
              INTO folders (resource_id, name)
            VALUES (_root_resource_id, 'test_folder_' || _random_admin_uuid || '_root');

            -- Grant 'admin' role to _user_a_id on _resources_folder_a_id (initial setup)
            INSERT
              INTO user_role_resource (resource_id, user_id, role_id)
            VALUES (_root_resource_id, _admin_id, (
                SELECT r.id
                  FROM roles r
                 WHERE r.name = 'admin'::ROLE
                                                  ))
                ON CONFLICT (user_id, resource_id) DO UPDATE SET role_id = excluded.role_id;


            BEGIN
                -- Test 01: Should fail to assign a role for a non-existent admin user
                BEGIN
                    PERFORM chmod( --
                            _admin_user_id := -1 --
                        , _resource_id := _root_resource_id --
                        , _user_id := _user_b_id --
                        , _role_type := 'editor'::ROLE --
                            );
                    RAISE EXCEPTION 'Validation for non-existent admin user failed';
                EXCEPTION
                    WHEN OTHERS THEN IF sqlerrm LIKE 'Admin user "%" does not exists.' THEN
                        RAISE NOTICE 'Test 01 passed: "Should fail to assign a role for non existing admin" - Expected exception: %',sqlerrm;
                    ELSE
                        RAISE NOTICE 'Test 01 failed: "Should fail to assign a role for non existing admin" - Unexpected exception: %',sqlerrm;
                    END IF;
                END;

                -- Test 02: Should fail to assign a role with a non-existent user_id
                BEGIN
                    PERFORM chmod(_admin_id, _root_resource_id, -1, 'admin'::ROLE);
                    RAISE EXCEPTION 'Validation for non-existent user failed';
                EXCEPTION
                    WHEN OTHERS THEN IF sqlerrm LIKE 'User "%" does not exist.' THEN
                        RAISE NOTICE 'Test 02 passed: "Should fail to assign a role with a non-existent user_id" - Expected exception: %', sqlerrm;
                    ELSE
                        RAISE NOTICE 'Test 02 failed: "Should fail to assign a role with a non-existent user_id" - Unexpected exception: %', sqlerrm;
                    END IF;
                END;


                -- Test 03: Should fail to assign a role for a non-existent resource_id
                BEGIN
                    PERFORM chmod(_admin_id, NULL, _user_b_id, 'editor'::ROLE);
                    RAISE EXCEPTION 'Validation for non-existent resource failed';
                EXCEPTION
                    WHEN OTHERS THEN IF sqlerrm LIKE 'Resource id cannot be NULL.' THEN
                        RAISE NOTICE 'Test 03 passed: "Should fail to assign a role for a non-existent resource_id" - Expected exception: %', sqlerrm;
                    ELSE
                        RAISE NOTICE 'Test 03 failed: "Should fail to assign a role for a non-existent resource_id" - Unexpected exception: %', sqlerrm;
                    END IF;
                END;

                -- Test 04: Should fail to assign a role for a non-existent resource_id
                BEGIN
                    PERFORM chmod(_admin_id, -1, _user_b_id, 'editor'::ROLE);
                    RAISE EXCEPTION 'Validation for non-existent resource failed';
                EXCEPTION
                    WHEN OTHERS THEN IF sqlerrm LIKE 'Resource with id "%" does not exist.' THEN
                        RAISE NOTICE 'Test 04 passed: "Should fail to assign a role for a non-existent resource_id" - Expected exception: %', sqlerrm;
                    ELSE
                        RAISE NOTICE 'Test 04 failed: "Should fail to assign a role for a non-existent resource_id" - Unexpected exception: %', sqlerrm;
                    END IF;
                END;

                -- Test 06: Should fail to assign a role with a wrong role type
                BEGIN
                    PERFORM chmod(_admin_id, _root_resource_id, _user_b_id, 'non_existent_role');
                    RAISE EXCEPTION 'Validation for non-existent role failed';
                EXCEPTION
                    WHEN OTHERS THEN IF sqlerrm LIKE 'asdasdadada' THEN
                        RAISE NOTICE 'Test 06 passed: "Should fail to assign a role with a wrong role type" - Expected exception: %', sqlerrm;
                    ELSE
                        RAISE NOTICE 'Test 06 failed: "Should fail to assign a role with a wrong role type" - Unexpected exception: %', sqlerrm;
                    END IF;
                END;

                -- Test 07:
                -- Should fail to assign a role to user if the admin does not have the `admin` role on the resource or any parent folders
                BEGIN
                    PERFORM chmod(_user_c_id, _root_resource_id, _user_b_id, 'editor'::ROLE);
                    RAISE EXCEPTION 'Validation admin-resource failed';
                EXCEPTION
                    WHEN OTHERS THEN IF sqlerrm LIKE
                                        'Admin User "%" does not have "admin" permissions on resource "%" or any parent folders.' THEN
                        RAISE NOTICE 'Test 07 passed: "Should fail to assign a role to user if the admin does not have the `admin` role on the resource" - Expected exception: %', sqlerrm;
                    ELSE
                        RAISE NOTICE 'Test 07 failed: "Should fail to assign a role to user if the admin does not have the `admin` role on the resource" - Unexpected exception: %', sqlerrm;
                    END IF;
                END;


                -- happy path tests


                BEGIN
                    /**
                     * Test 08: Assign 'editor' role to _user_b_id
                     */
                    PERFORM chmod( --
                            _admin_id, _root_resource_id, _user_b_id, 'editor'::ROLE);
                    IF exists(
                        SELECT 1
                          FROM user_role_resource uur
                         WHERE uur.resource_id = _root_resource_id
                           AND uur.user_id = _user_b_id
                           AND uur.role_id = (
                             SELECT r.id
                               FROM roles r
                              WHERE r.name = 'editor'::ROLE
                                             )
                             ) THEN
                        RAISE NOTICE 'Test 08 passed: "Should assign the `editor` role for `_root_resource_id` to the user `_user_b_id`"';
                    ELSE
                        RAISE EXCEPTION 'Test 08 failed: "Should assign the `editor` role for `_root_resource_id` to the user `_user_b_id`"';
                    END IF;
                END;

                BEGIN
                    -- Test 09: Admins should be able to assign the roles to user/resource even for nested folders

                    -- ARRANGE: Create nested folder
                       INSERT
                         INTO resources (created_by, updated_by, type, parent_folder_id)
                       VALUES (_user_b_id, _user_b_id, 'folder'::RESOURCE, _root_resource_id)
                    RETURNING id INTO _nested_folder_resource_id;

                    INSERT
                      INTO folders (resource_id, name)
                    VALUES (_nested_folder_resource_id, 'test_folder_' || _random_admin_uuid || '_nested');

                    PERFORM chmod(_admin_id, _nested_folder_resource_id, _user_b_id, 'viewer'::ROLE);


                    IF exists (
                        SELECT 1
                          FROM virtual_file_system.public.user_role_resource uur
                         WHERE uur.resource_id = _nested_folder_resource_id
                           AND uur.user_id = _user_b_id
                           AND uur.role_id = (
                             SELECT id
                               FROM roles
                              WHERE name = 'viewer'::ROLE
                                             )
                              ) THEN
                        RAISE NOTICE 'Test 09 passed: "Admins should be able to assign the roles to user/resource even for nested folders"';
                    ELSE
                        RAISE EXCEPTION 'Test 09 failed: "Admins should be able to assign the roles to user/resource even for nested folders"';
                    END IF;
                END;


            EXCEPTION
                WHEN OTHERS THEN --
                    RAISE NOTICE 'Exception: %', sqlerrm;
            END;


            -- AFTER ALL -> Tear down: Cleanup test data
            BEGIN
                DELETE FROM resources r WHERE r.id = _nested_folder_resource_id;
                DELETE FROM resources r WHERE r.id = _root_resource_id;

                DELETE FROM users u WHERE u.id = _user_c_id;
                DELETE FROM users u WHERE u.id = _user_b_id;
                DELETE FROM users u WHERE u.id = _admin_id;
                RAISE NOTICE 'Cleanup `chmod` test data completed';
            EXCEPTION
                WHEN OTHERS THEN RAISE NOTICE 'Cleanup failed: %', sqlerrm;
            END;
        END;
    END;
$$;
ROLLBACK;
