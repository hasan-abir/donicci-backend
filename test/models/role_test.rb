require "test_helper"

class RoleTest < ActiveSupport::TestCase
  teardown do
    Role.delete_all
  end

  test "should save" do
    assert role_instance.save
  end

  test "should not save when name isn't provided" do
    role = role_instance
    role.name = nil
    assert_not role.save
    assert role.errors.full_messages.include? "Name must be provided"
  end

  test "should not save when name isn't an enumerable" do
    role = role_instance
    role.name = "ROLE_MODERATOR"
    assert_not role.save
    assert role.errors.full_messages.include? "Name must include: ROLE_USER | ROLE_ADMIN"
  end

  test "should not save when role already exists" do
    role = role_instance
    assert role.save

    roleCopy =  role_instance
    assert_not roleCopy.save
    assert roleCopy.errors.full_messages.include? "Name 'ROLE_USER' already exists" 
  end

  def role_instance(name = "ROLE_USER")
    role = Role.new
    role.name = name

    return role
  end  
end
