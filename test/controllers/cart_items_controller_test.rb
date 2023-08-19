require "test_helper"

class CartItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner[:mongoid].start

    user = user_instance
    
    role_admin = role_instance("ROLE_ADMIN")
    role_admin.save
    role_mod = role_instance("ROLE_MODERATOR")
    role_mod.save
    role_user = role_instance("ROLE_USER")
    role_user.save

    user.role_ids.push(role_admin._id)

    user.save
  end

  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "index: gets the result" do
    x = 1
    
    author = User.where(username: "hasan_abir1999").first
    role_user = Role.where(name: "ROLE_USER").first
    other_user = user_instance
    other_user.roles.push(role_user)
    other_user.save

    token = generate_token

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

    get "/cart/", headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert response.first["_id"]
    assert response.first["product_title"]
    assert response.first["product_price"]
    assert response.first["product_quantity"]
    assert response.first["selected_quantity"]
    assert_not response.first["product_id"] 
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

    token = generate_token

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status

    assert response["_id"]
    assert response["product_title"]
    assert response["product_price"]
    assert response["product_quantity"]
    assert response["selected_quantity"]

    cartItems = CartItem.all
    assert_equal 1, cartItems.length
  end

  test "create: doesn't create cart item if a user adds a product twice" do
    product = product_instance
    product.save

    item = {selected_quantity: 1, product_id: product._id}

    token = generate_token

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    assert_equal 200, @response.status

    cartItems = CartItem.all
    assert_equal 1, cartItems.length

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status

    assert response["msgs"].include? "Product is already in the cart for this user"
  end

  test "create: doesn't create cart item without item params" do
    product = product_instance
    product.save

    token = generate_token

    post "/cart/", params: {}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

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

    token = generate_token
    
    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

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

    token = generate_token

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

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

    token = generate_token

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

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

    token = generate_token

    post "/cart/", params: {item: item}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Selected quantity exceeds the stock", response["msg"]

    cartItems = CartItem.all
    assert_equal 0, cartItems.length
  end

  test "destroy: deletes cart item" do
    product = product_instance
    product.save

    token = generate_token

    author = User.where(username: "hasan_abir1999").first

    cartItem = cart_item_instance(1)
    cartItem.product_id = product._id
    cartItem.user_id = author._id
    cartItem.save

    delete "/cart/" + cartItem._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    assert_equal 201, @response.status

    cartItems = CartItem.all
    assert_equal 0, cartItems.length
  end

  test "destroy: doesn't delete cart item without authentication" do
    product = product_instance
    product.save

    author = User.where(username: "hasan_abir1999").first

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
    token = generate_token

    delete "/cart/123", headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

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
    other_user = user_instance("other_user456", "otheruser@test.com")
    other_user.roles.push(role_user)
    other_user.save

    cartItem = cart_item_instance(1)
    cartItem.product_id = product._id
    cartItem.user_id = other_user._id
    cartItem.save

    token = generate_token

    delete "/cart/" + cartItem._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]

    cartItems = CartItem.all
    assert_equal 1, cartItems.length
  end

  test "destroy_all: deletes cart all items" do
    x = 1
    
    author = User.where(username: "hasan_abir1999").first
    role_user = Role.where(name: "ROLE_USER").first
    other_user = user_instance("other_user456", "otheruser@test.com")
    other_user.roles.push(role_user)
    other_user.save

    token = generate_token
    
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

    delete "/cart/all", headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    assert_equal 201, @response.status

    cartItems = CartItem.all
    assert_equal 1, cartItems.length
  end

  test "destroy_all: doesn't deletes cart items without authentication" do
    x = 1
    
    author = User.where(username: "hasan_abir1999").first
    role_user = Role.where(name: "ROLE_USER").first
    other_user = user_instance("other_user456", "otheruser@test.com")
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
end
