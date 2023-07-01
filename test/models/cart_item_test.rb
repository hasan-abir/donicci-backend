require "test_helper"

class CartItemTest < ActiveSupport::TestCase
  setup do
    DatabaseCleaner[:mongoid].start
  end
    
  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "cart_item: should save" do
    cart_item = cart_item_instance
    product = product_instance
    product.save
    user = user_instance
    role = role_instance
    user.role_ids.push(role._id)
    user.save
    cart_item.user_id = user._id
    cart_item.product_id = product._id
    assert cart_item.save
  end

  test "cart_item: should not save when selected_quantity isn't provided" do
    cart_item = cart_item_instance
    cart_item.selected_quantity = nil

    assert_not cart_item.save
    assert cart_item.errors.full_messages.include? "Selected quantity must be provided"
  end

  test "cart_item: should not save when selected_quantity isn't number" do
    cart_item = cart_item_instance
    cart_item.selected_quantity = 1.5

    assert_not cart_item.save
    assert cart_item.errors.full_messages.include? "Selected quantity must be an integer"
  end

  test "cart_item: should not save when selected_quantity is less than 1" do
    cart_item = cart_item_instance
    cart_item.selected_quantity = 0

    assert_not cart_item.save
    assert cart_item.errors.full_messages.include? "Selected quantity must be greater than or equal to 1"
  end
end
