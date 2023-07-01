require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  setup do
    DatabaseCleaner[:mongoid].start
  end
    
  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "category: does save" do
    assert category_instance.save
  end

  test "category: does not save when name is nil" do
    category = category_instance
    category.name = nil

    assert_not category.save
    assert category.errors.full_messages.include? "Name must be provided"
  end
end
