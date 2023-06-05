require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  teardown do
    User.delete_all
    Role.delete_all
  end  

  test "create: saves user" do
    role = Role.new
    role.name = "ROLE_ADMIN"
    role.save

    user = {username: "Test", email: "test@test.com", password: "testtest", roles: [role.name]}
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
    assert_equal 1, usersSaved.length
  end

  
  test "create: doesn't saves user with invalid fields" do
    post "/auth/register/", params: {user: {username: nil, email: "test@test.com", password: "testtest"}}

    response = JSON.parse(@response.body)

    assert_equal 400, @response.status
    assert_equal ["Username must be provided", "Role ids length should be 1 minimum"], response["msgs"]

    usersSaved = User.all
    assert_equal 0, usersSaved.length
  end

  test "create: doesn't saves no user in request body" do
    post "/auth/register/", params: {}

    response = JSON.parse(@response.body)

    assert_equal 400, @response.status
    assert_equal "Requires 'user' in request body with fields: username email roles password", response["msg"]

    usersSaved = User.all
    assert_equal 0, usersSaved.length
  end
end
