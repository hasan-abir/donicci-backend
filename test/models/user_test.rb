require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    DatabaseCleaner[:mongoid].start
  end
    
  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "user: should save" do
    user = user_instance
    role = role_instance
    user.role_ids.push(role._id)
    
    assert user.save
  end  

  test "user: shouldn't save (presence validation)" do
    user = user_instance(nil, nil, nil, nil)
    role = role_instance
    user.role_ids.push(role._id)

    assert_not user.save
    assert user.errors.full_messages.include? "Email must be provided"
    assert user.errors.full_messages.include? "Username must be provided"
    assert user.errors.full_messages.include? "Display name must be provided"
    assert user.errors.full_messages.include? "Password can't be blank"
  end  

  test "user: shouldn't save (format validation)" do
    user = user_instance
    user.username = "hasan"
    assert_not user.save
    user.username = "hasan_abir"
    assert_not user.save

    assert user.errors.full_messages.include? "Username must contain lowercase letters, numbers, and underscores"

    user.email = "testtest.com"

    assert_not user.save
    assert user.errors.full_messages.include? "Email address is invalid"
  end 

  test "user: shouldn't save (length validation)" do
    user = user_instance
    user.password = "testtes"

    user.save

    assert user.errors.full_messages.include? "Password length should be 8 characters minimum"
  end

  test "user: shouldn't save with existing username and/or email" do
    firstUser = user_instance
    role = role_instance
    firstUser.role_ids.push(role._id)
    assert firstUser.save

    secondUser = user_instance
    role = role_instance
    secondUser.role_ids.push(role._id)

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
end
