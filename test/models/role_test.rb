require "test_helper"

class RoleTest < ActiveSupport::TestCase
  setup do
    DatabaseCleaner[:mongoid].start
  end
    
  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "role: should save" do
    assert role_instance.save
  end

  test "role: should not save when name isn't provided" do
    role = role_instance
    role.name = nil
    assert_not role.save
    assert role.errors.full_messages.include? "Name must be provided"
  end

  test "role: should not save when name doesn't start with role_" do
    role = role_instance
    role.name = "STAFF"
    assert_not role.save
    assert role.errors.full_messages.include? "Name must start with 'role_'"
  end

  test "role: should not save when role already exists" do
    role = role_instance
    assert role.save

    roleCopy =  role_instance
    roleCopy.save
    assert_not roleCopy.save

    assert roleCopy.errors.full_messages.include? "Name 'ROLE_USER' already exists" 
    assert_equal 1, Role.all.length
  end
end
