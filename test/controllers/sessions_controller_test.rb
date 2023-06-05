require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  teardown do
    RefreshToken.delete_all
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

    assert response["access_token"]
    assert response["refresh_token"]

    refresh_tokens = RefreshToken.all

    assert_equal 1, refresh_tokens.length
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

  test "refresh: does refresh token" do
    refresh_token = refresh_token_instance
    refresh_token.save

    params = {token: refresh_token.token}
    post "/auth/refresh-token/", params: params

    response = JSON.parse(@response.body)
    
    assert_equal 200, @response.status

    assert response["access_token"]
    assert response["refresh_token"]

    tokensSaved = RefreshToken.all
    assert_equal 1, tokensSaved.length

    prev_token = RefreshToken.find_by(token: refresh_token.token)
    assert_not prev_token

    current_token = RefreshToken.find_by(token: response["refresh_token"])
    assert current_token
  end

  test "refresh: doesn't refresh token when user is not found" do
    refresh_token = refresh_token_instance
    refresh_token.save

    User.delete_all

    params = {token: refresh_token.token}
    post "/auth/refresh-token/", params: params

    response = JSON.parse(@response.body)
    
    assert_equal 401, @response.status

    assert_equal "User does not exist anymore", response["msg"]
  end

  test "refresh: doesn't refresh token when token not found" do
    params = {token: "123"}
    post "/auth/refresh-token/", params: params

    response = JSON.parse(@response.body)
    
    assert_equal 401, @response.status

    assert_equal "Token not found", response["msg"]

    tokensSaved = RefreshToken.all
    assert_equal 0, tokensSaved.length
  end

  test "refresh: doesn't refresh token without token" do
    params = {}
    post "/auth/refresh-token/", params: params

    response = JSON.parse(@response.body)
    
    assert_equal 401, @response.status

    assert_equal "No token provided", response["msg"]

    tokensSaved = RefreshToken.all
    assert_equal 0, tokensSaved.length
  end

  test "destroy: does logout user" do
    refresh_token = refresh_token_instance
    refresh_token.save

    params = {token: refresh_token.token}
    delete "/auth/logout/", params: params

    assert_equal 201, @response.status

    tokensSaved = RefreshToken.all
    assert_equal 0, tokensSaved.length
  end

  test "destroy: doesn't logout user when token not found" do
    params = {token: "123"}
    delete "/auth/logout/", params: params

    response = JSON.parse(@response.body)

    assert_equal 401, @response.status
    assert_equal "Token not found", response["msg"]
    

    tokensSaved = RefreshToken.all
    assert_equal 0, tokensSaved.length
  end

  test "destroy: doesn't logout user without token" do
    params = {}
    delete "/auth/logout/", params: params

    response = JSON.parse(@response.body)

    assert_equal 401, @response.status
    assert_equal "No token provided", response["msg"]
    

    tokensSaved = RefreshToken.all
    assert_equal 0, tokensSaved.length
  end

  def refresh_token_instance() 
    user = user_instance
    refresh_token = RefreshToken.new
    refresh_token.token = JWT.encode({ user_id: user._id }, Rails.application.secret_key_base)

    user.save
    refresh_token.user = user

    refresh_token
  end

  def user_instance(username = "test", email = "test@test.com", password = "testtest")
    role = role_instance
    role.save

    user = User.new
    user.username = username
    user.email = email
    user.password = password
    user.roles.push(role)

    user
  end  

  def role_instance(name = "ROLE_USER")
    role = Role.new
    role.name = name

    role
  end  
end
