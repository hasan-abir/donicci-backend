require "test_helper"

class RolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner[:mongoid].start

    user = user_instance
    
    role_admin = role_instance("role_admin")
    role_admin.save
    role_user = role_instance
    role_user.save

    user.role_ids.push(role_admin._id)

    user.save
  end

  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "assign_role: assigns role to a user" do
    token = generate_token("admin")

    role = Role.where(name: "ROLE_ADMIN").first

    user = user_instance("test_user456", "testuser@test.com", "testtest", "Test User")
    user_role = Role.where(name: "ROLE_USER").first
    user.role_ids.push(user_role._id)
    user.save

    put "/roles/" + role._id + "/user/" + user.username, headers: {"HTTP_AUTHORIZATION"  => "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 200, @response.status
    assert_equal "'" + user.username + "' has been assigned role: '" + role.name + "'", response["msg"]

    savedUser = User.where(username: user.username).first

    assert_equal 2, savedUser.role_ids.length
    assert_equal role._id, savedUser.role_ids.last
  end

  test "assign_role: doesn't assign role to a user if not authenticated" do
    role = Role.where(name: "ROLE_ADMIN").first

    user = user_instance("test_user456", "testuser@test.com", "testtest", "Test User")
    user_role = Role.where(name: "ROLE_USER").first
    user.role_ids.push(user_role._id)
    user.save

    put "/roles/" + role._id + "/user/" + user.username

    response = JSON.parse(@response.body)

    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]

    savedUser = User.where(username: user.username).first

    assert_equal 1, savedUser.role_ids.length
  end

  test "assign_role: doesn't assign role to a user if not authorized" do
    token = generate_token

    role = Role.where(name: "ROLE_ADMIN").first

    user = user_instance("test_user456", "testuser@test.com", "testtest", "Test User")
    user_role = Role.where(name: "ROLE_USER").first
    user.role_ids.push(user_role._id)
    user.save

    put "/roles/" + role._id + "/user/" + user.username, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]

    savedUser = User.where(username: user.username).first

    assert_equal 1, savedUser.role_ids.length
  end

  test "assign_role: doesn't assigns role to a user if user is not found" do
    token = generate_token("admin")

    role = Role.where(name: "ROLE_ADMIN").first

    put "/roles/" + role._id + "/user/user_test123", headers: {"HTTP_AUTHORIZATION"  => "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 404, @response.status
    assert_equal "User not found", response["msg"]

    assert_equal 1, User.all.length
  end
end
 