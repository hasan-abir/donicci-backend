require "test_helper"

class CartItemTest < ActiveSupport::TestCase
  teardown do
    CartItem.delete_all
    Product.delete_all
    User.delete_all
  end  

  test "should save" do
    assert cart_item_instance.save
  end

  test "should not save when selected_quantity isn't provided" do
    cart_item = cart_item_instance
    cart_item.selected_quantity = nil

    assert_not cart_item.save
  end

  test "should not save when selected_quantity isn't number" do
    cart_item = cart_item_instance
    cart_item.selected_quantity = 1.5

    assert_not cart_item.save
  end

  test "should not save when selected_quantity is less than 1" do
    cart_item = cart_item_instance
    cart_item.selected_quantity = 0

    assert_not cart_item.save
  end

  def cart_item_instance(quantity = 10) 
    cartItem = CartItem.new
    cartItem.selected_quantity = quantity
    product = product_instance
    product.save
    cartItem.product = product
    user = user_instance
    user.save
    cartItem.user = user

    return cartItem
  end
  def product_instance(product_title = "test product") 
    product = Product.new
    product.title = product_title
    product.images = [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}]
    product.price = 300
    product.quantity = 1

    return product
  end
  def user_instance(username = "Test", email = "test@test.com")
    user = User.new
    user.username = username
    user.email = email
    user.password_hash = "bcrypthash"
    user.password_salt = "bcryptsalt"

    return user
  end
end
