require "test_helper"

class CartItemsControllerTest < ActionDispatch::IntegrationTest
  teardown do
    CartItem.delete_all
    Product.delete_all
    User.delete_all
    Role.delete_all
  end

  setup do
    role_user = role_instance("ROLE_USER")
    role_user.save

    user = user_instance("User Hasan Abir", "usertest@test.com")
    user.roles.push(role_user)

    user.save

    @user_token = JWT.encode({ user_id: user._id }, Rails.application.secret_key_base)
  end

  test "index: gets the result" do
    x = 1
    
    author = User.where(username: "User Hasan Abir").first
    role_user = Role.where(name: "ROLE_USER").first
    other_user = user_instance
    other_user.roles.push(role_user)
    other_user.save
    
    while(x <= 6)
      product = product_instance
      product.save

      cartItem = cart_item_instance(1)

      cartItem.product_id = product._id
      if x < 6
        cartItem.user_id = author._id
      else
        cartItem.user_id = other_user._id
      end

      cartItem.save

      x = x + 1
    end

    get "/cart/", headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert response.first["_id"]
    assert response.first["selected_quantity"]
    assert response.first["product_id"]
    assert response.first["user_id"]
  end

  test "index: doesn't get the result without authentication" do
    get "/cart/"

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]
  end

  test "create: creates cart item" do
    product = product_instance
    product.save

    item = {selected_quantity: 1, product_id: product._id}

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert response["_id"]
    assert response["selected_quantity"]
    assert response["product_id"]
    assert response["user_id"]

    cartItems = CartItem.all
    assert_equal 1, cartItems.length
  end

  test "create: doesn't create cart item without item params" do
    product = product_instance
    product.save

    post "/cart/", params: {}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'item' in request body with fields: selected_quantity product_id", response["msg"]

    cartItems = CartItem.all
    assert_equal 0, cartItems.length
  end

  test "create: doesn't create cart item with empty/invalid fields" do
    product = product_instance
    product.save

    item = {selected_quantity: nil, product_id: product._id}

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Selected quantity must be provided"

    cartItems = CartItem.all
    assert_equal 0, cartItems.length
  end

  test "create: doesn't create cart item without authentication" do
    product = product_instance
    product.save

    item = {selected_quantity: 1, product_id: product._id}

    post "/cart/", params: {item: item}

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]

    cartItems = CartItem.all
    assert_equal 0, cartItems.length
  end

  test "create: doesnt create cart item when there's no product" do
    item = {selected_quantity: 1, product_id: "123"}

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 404, @response.status
    assert_equal "Product not found", response["msg"]

    cartItems = CartItem.all
    assert_equal 0, cartItems.length
  end

  test "create: doesn't create cart item when quantity is less than 1" do
    product = product_instance
    product.save

    item = {selected_quantity: 0, product_id: product._id}

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Selected quantity must be greater than or equal to 1"

    cartItems = CartItem.all
    assert_equal 0, cartItems.length
  end

  test "create: doesn't create cart item when quantity is more than stock" do
    product = product_instance
    product.save

    item = {selected_quantity: product.quantity + 1, product_id: product._id}

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Selected quantity exceeds the stock", response["msg"]

    cartItems = CartItem.all
    assert_equal 0, cartItems.length
  end

  test "destroy: deletes cart item" do
    product = product_instance
    product.save

    author = User.where(username: "User Hasan Abir").first

    cartItem = cart_item_instance(1)
    cartItem.product_id = product._id
    cartItem.user_id = author._id
    cartItem.save

    delete "/cart/" + cartItem._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    assert_equal 201, @response.status

    cartItems = CartItem.all
    assert_equal 0, cartItems.length
  end

  test "destroy: doesn't delete cart item without authentication" do
    product = product_instance
    product.save

    author = User.where(username: "User Hasan Abir").first

    cartItem = cart_item_instance(1)
    cartItem.product_id = product._id
    cartItem.user_id = author._id
    cartItem.save

    delete "/cart/" + cartItem._id

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]

    cartItems = CartItem.all
    assert_equal 1, cartItems.length
  end
  
  test "destroy: doesn't delete cart item when not found" do
    delete "/cart/123", headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 404, @response.status
    assert_equal "Cart item not found", response["msg"]

    cartItems = CartItem.all
    assert_equal 0, cartItems.length
  end

  test "destroy: doesn't delete cart item as a different user" do
    product = product_instance
    product.save

    role_user = Role.where(name: "ROLE_USER").first
    other_user = user_instance
    other_user.roles.push(role_user)
    other_user.save

    cartItem = cart_item_instance(1)
    cartItem.product_id = product._id
    cartItem.user_id = other_user._id
    cartItem.save

    delete "/cart/" + cartItem._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]

    cartItems = CartItem.all
    assert_equal 1, cartItems.length
  end

  test "destroy_all: deletes cart all items" do
    x = 1
    
    author = User.where(username: "User Hasan Abir").first
    role_user = Role.where(name: "ROLE_USER").first
    other_user = user_instance
    other_user.roles.push(role_user)
    other_user.save
    
    while(x <= 6)
      product = product_instance
      product.save

      cartItem = cart_item_instance(1)

      cartItem.product_id = product._id
      if x < 6
        cartItem.user_id = author._id
      else
        cartItem.user_id = other_user._id
      end

      cartItem.save

      x = x + 1
    end

    delete "/cart/all", headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    assert_equal 201, @response.status

    cartItems = CartItem.all
    assert_equal 1, cartItems.length
  end

  test "destroy_all: doesn't deletes cart items without authentication" do
    x = 1
    
    author = User.where(username: "User Hasan Abir").first
    role_user = Role.where(name: "ROLE_USER").first
    other_user = user_instance
    other_user.roles.push(role_user)
    other_user.save
    
    while(x <= 6)
      product = product_instance
      product.save

      cartItem = cart_item_instance(1)

      cartItem.product_id = product._id
      if x < 6
        cartItem.user_id = author._id
      else
        cartItem.user_id = other_user._id
      end

      cartItem.save

      x = x + 1
    end

    delete "/cart/all"

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]

    cartItems = CartItem.all
    assert_equal 6, cartItems.length
  end

  def cart_item_instance(quantity = 10) 
    cartItem = CartItem.new
    cartItem.selected_quantity = quantity

    cartItem
  end
  def product_instance(product_title = "test product") 
    product = Product.new
    product.title = product_title
    product.images = [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}]
    product.price = 300
    product.quantity = 1
    product.user_rating = 0

    product
  end
  def user_instance(username = "Hasan Abir", email = "test@test.com") 
    user = User.new
    user.username = username
    user.email = email
    user.password = "testtest"

    user
  end
  def role_instance(name = "ROLE_ADMIN") 
    role = Role.new
    role.name = name

    role
  end
end
