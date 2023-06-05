require "test_helper"

class UserTest < ActiveSupport::TestCase
  teardown do
    User.delete_all
    Role.delete_all
  end

  test "user: should save" do
    user = user_instance

    assert user.save
    assert_equal user.username.to_s.titleize, user.username
  end  

  test "user: shouldn't save with empty fields" do
    user = user_instance(nil, nil, nil)

    assert_not user.save
    assert user.errors.full_messages.include? "Email must be provided"
    assert user.errors.full_messages.include? "Username must be provided"
    assert user.errors.full_messages.include? "Password can't be blank"
  end  

  test "user: shouldn't save with invalid email" do
    user = user_instance
    user.email = "testtest.com"

    assert_not user.save
    assert user.errors.full_messages.include? "Email address is invalid"
  end  

  test "user: shouldn't save with invalid password" do
    user = user_instance
    user.password = "testtes"

    assert_not user.save
    assert user.errors.full_messages.include? "Password length should be 8 characters minimum"
  end  

  test "user: shouldn't save with existing username and/or email" do
    firstUser = user_instance
    assert firstUser.save

    secondUser = user_instance

    assert_not secondUser.save

    assert secondUser.errors.full_messages.include? "Email must be unique"
    assert secondUser.errors.full_messages.include? "Username must be unique"
  end 

  test "user: shouldn't save with no roles" do
    user = user_instance
    user.role_ids = []
    assert_not user.save

    assert user.errors.full_messages.include? "Role ids length should be 1 minimum"
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
