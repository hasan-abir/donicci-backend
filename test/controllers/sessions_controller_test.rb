require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner[:mongoid].start
  end

  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "create: returns token" do
    user = user_instance
    role = role_instance
    user.role_ids.push(role._id)
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

  test "create: doesn't create multiple tokens on multiple requests" do
    user = user_instance
    role = role_instance
    user.role_ids.push(role._id)
    user.save

    credentials = {email: "test@test.com", password: "testtest"}
    post "/auth/login/", params: credentials
    
    assert_equal 200, @response.status

    post "/auth/login/", params: credentials

    assert_equal 200, @response.status
    response = JSON.parse(@response.body)

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

    travel_to(Time.now + 30.minutes) do
      response = JSON.parse(@response.body)
    
      assert_equal 200, @response.status

      assert response["access_token"]
      assert response["refresh_token"]

      tokensSaved = RefreshToken.all
      assert_equal 1, tokensSaved.length

      assert refresh_token.token == response["refresh_token"]

      current_token = RefreshToken.find_by(token: response["refresh_token"])
      assert current_token
    end
  end

  test "refresh: doesn't refresh token when token expires" do
    ENV['REFRESH_EXPIRATION_HOURS'] = "1"
    refresh_token = refresh_token_instance
    refresh_token.save

    travel_to(Time.now + 2.hours) do
      params = {token: refresh_token.token}
      post "/auth/refresh-token/", params: params
  
      response = JSON.parse(@response.body)
      
      assert_equal 401, @response.status
  
      assert_equal "Unauthorized", response["msg"]
      tokensSaved = RefreshToken.all
      assert_equal 0, tokensSaved.length
    end
  end

  test "refresh: doesn't refresh token when user is not found" do
    refresh_token = refresh_token_instance
    refresh_token.save

    User.delete_all

    params = {token: refresh_token.token}
    post "/auth/refresh-token/", params: params

    response = JSON.parse(@response.body)
    
    assert_equal 404, @response.status

    assert_equal "User does not exist anymore", response["msg"]
    tokensSaved = RefreshToken.all
    assert_equal 0, tokensSaved.length
  end

  test "refresh: doesn't refresh token when token not found" do
    params = {token: "123"}
    post "/auth/refresh-token/", params: params

    response = JSON.parse(@response.body)
    
    assert_equal 404, @response.status

    assert_equal "Token not found", response["msg"]

    tokensSaved = RefreshToken.all
    assert_equal 0, tokensSaved.length
  end

  test "refresh: doesn't refresh token without token" do
    params = {}
    post "/auth/refresh-token/", params: params

    response = JSON.parse(@response.body)
    
    assert_equal 400, @response.status

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
end
