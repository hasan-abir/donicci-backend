require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  teardown do
    User.delete_all
    Role.delete_all
  end

  test "create: returns token" do
    user = user_instance
    user.save

    credentials = {email: "test@test.com", password: "testtest"}
    post "/auth/login/", params: credentials

    response = JSON.parse(@response.body)
    
    assert_equal 200, @response.status

    assert response["token"]
  end

  test "create: returns error when email is incorrect" do
    user = user_instance
    user.save

    credentials = {email: "tests@test.com", password: "testtest"}
    post "/auth/login/", params: credentials

    response = JSON.parse(@response.body)
    
    assert_equal 401, @response.status

    assert_equal "Invalid email or password", response["msg"]
  end

  test "create: returns error when password is incorrect" do
    user = user_instance
    user.save

    credentials = {email: "test@test.com", password: "testtests"}
    post "/auth/login/", params: credentials

    response = JSON.parse(@response.body)
    
    assert_equal 401, @response.status

    assert_equal "Invalid email or password", response["msg"]
  end

  def user_instance(username = "test", email = "test@test.com", password = "testtest")
    role = role_instance
    role.save

    user = User.new
    user.username = username
    user.email = email
    user.password = password
    user.roles.push(role)

    return user
  end

  def role_instance(name = "ROLE_USER")
    role = Role.new
    role.name = name

    return role
  end  
end
