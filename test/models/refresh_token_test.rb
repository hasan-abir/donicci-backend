require "test_helper"

class RefreshTokenTest < ActiveSupport::TestCase
  teardown do
    RefreshToken.delete_all
    User.delete_all
    Role.delete_all
  end  

  test "refresh_token: should save" do
    refresh_token = refresh_token_instance

    assert refresh_token.save
  end

  test "refresh_token: should not save without token" do
    refresh_token = refresh_token_instance
    refresh_token.token = nil

    assert_not refresh_token.save
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
