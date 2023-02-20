require "test_helper"

class UserTest < ActiveSupport::TestCase
  teardown do
    User.delete_all
    Role.delete_all
  end

  test "should save" do
    assert user_instance.save
  end

  test "should save with roles" do
    adminRole = role_instance("ROLE_ADMIN")
    userRole = role_instance
    adminRole.save
    userRole.save

    user = user_instance
    user.roles.push(adminRole)
    user.roles.push(userRole)

    assert_equal(2, user.roles.length)
    assert user.save
  end

  test "should not save when username isn't provided" do
    user = user_instance
    user.username = nil
    assert_not user.save
  end

  test "should not save when username already exists" do
    user = user_instance
    assert user.save

    userCopy = user_instance
    assert_not userCopy.save
  end

  test "should not save when email isn't provided" do
    user = user_instance
    user.email = nil
    assert_not user.save
  end

  test "should not save when email isn't valid" do
    user = user_instance
    user.email = "testtest.com"
    assert_not user.save
  end

  test "should not save when email already exists" do
    user = user_instance
    assert user.save

    userCopy = user_instance("Test 2")
    assert_not userCopy.save
  end

  test "should not save when password_hash isn't provided" do
    user = user_instance
    user.password_hash = nil
    assert_not user.save
  end

  test "should not save when password_salt isn't provided" do
    user = user_instance
    user.password_salt = nil
    assert_not user.save
  end

  def user_instance(username = "Test", email = "test@test.com")
    user = User.new
    user.username = username
    user.email = email
    user.password_hash = "bcrypthash"
    user.password_salt = "bcryptsalt"

    return user
  end  
  def role_instance(name = "ROLE_USER")
    role = Role.new
    role.name = name

    return role
  end  
end
