require "test_helper"

class CartItemTest < ActiveSupport::TestCase
  teardown do
    CartItem.delete_all
    Product.delete_all
    User.delete_all
    Role.delete_all
  end  

  test "cart_item: should save" do
    assert cart_item_instance.save
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

  def cart_item_instance(quantity = 10) 
    cartItem = CartItem.new
    cartItem.selected_quantity = quantity
    product = product_instance
    product.save
    cartItem.product = product
    user = user_instance
    user.save
    cartItem.user = user

    cartItem
  end
  def product_instance(product_title = "test product") 
    product = Product.new
    product.title = product_title
    product.images = [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}]
    product.price = 300
    product.quantity = 1

    product
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
