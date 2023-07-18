require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner[:mongoid].start
  end

  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "create: saves user" do
    role = role_instance
    role.save

    user = {display_name: "Test User", username: "test_user123", email: "test@test.com", password: "testtest"}
    post "/auth/register/", params: {user: user}

    response = JSON.parse(@response.body)

    assert_equal 200, @response.status
    assert_equal user[:username], response["username"]
    assert_equal user[:email], response["email"]
    assert_not response["_id"]
    assert_not response["updated_at"]
    assert_not response["created_at"]
    assert_not response["password_digest"]

    usersSaved = User.all
    rolesSaved = Role.all
    assert_equal 1, usersSaved.length
    assert_equal 1, rolesSaved.length
  end

  test "create: saves user without needing to create new role" do
    user = {display_name: "Test User", username: "test_user123", email: "test@test.com", password: "testtest"}
    post "/auth/register/", params: {user: user}

    response = JSON.parse(@response.body)

    assert_equal 200, @response.status
    assert_equal user[:username], response["username"]
    assert_equal user[:email], response["email"]
    assert_not response["_id"]
    assert_not response["updated_at"]
    assert_not response["created_at"]
    assert_not response["password_digest"]

    usersSaved = User.all
    rolesSaved = Role.all
    assert_equal 1, usersSaved.length
    assert_equal 1, rolesSaved.length
  end

  
  test "create: doesn't save user with invalid fields" do
    post "/auth/register/", params: {user: {username: nil, email: "test@test.com", password: "testtest"}}

    response = JSON.parse(@response.body)

    assert_equal 400, @response.status
    assert_equal ["Username must be provided", "Display name must be provided", "Username must contain lowercase letters, numbers, and underscores"], response["msgs"]

    usersSaved = User.all
    assert_equal 0, usersSaved.length
  end

  test "create: doesn't save no user in request body" do
    post "/auth/register/", params: {}

    response = JSON.parse(@response.body)

    assert_equal 400, @response.status
    assert_equal "Requires 'user' in request body with fields: display_name username email roles password", response["msg"]

    usersSaved = User.all
    assert_equal 0, usersSaved.length
  end
end
