require "test_helper"

class ProductsControllerCreateTest < ActionDispatch::IntegrationTest
  setup do
    role_admin = role_instance("ROLE_ADMIN")
    role_admin.save
    role_user = role_instance("ROLE_USER")
    role_user.save
    role_mod = role_instance("ROLE_MODERATOR")
    role_mod.save

    admin = user_instance
    admin.roles.push(role_admin)
    user = user_instance("User Hasan Abir", "usertest@test.com")
    user.roles.push(role_user)
    mod = user_instance("Mod Hasan Abir", "modtest@test.com")
    mod.roles.push(role_mod)

    user.save
    admin.save
    mod.save

    @admin_token = JWT.encode({ user_id: admin._id }, Rails.application.secret_key_base)
    @user_token = JWT.encode({ user_id: user._id }, Rails.application.secret_key_base)
    @mod_token = JWT.encode({ user_id: mod._id }, Rails.application.secret_key_base)
  end

  teardown do
    Product.delete_all
    Category.delete_all
    User.delete_all
    Role.delete_all
  end  

  test "create: saves product" do
    product = {title: "Product", description: "Lorem", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 1}

    post "/products/", params: {product: product}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }
    

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal product[:title], response["title"]

    productsSaved = Product.all
    assert_equal 1, productsSaved.length
  end

  test "create: saves product as a moderator" do
    product = {title: "Product", description: "Lorem", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 1}

    post "/products/", params: {product: product}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @mod_token }
    

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal product[:title], response["title"]

    productsSaved = Product.all
    assert_equal 1, productsSaved.length
  end

  test "create: doesn't save product without authentication" do
    post "/products/", params: {product: {title: "Product", description: "Lorem", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 1}}
    

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save product without permission" do
    post "/products/", params: {product: {title: "Product", description: "Lorem", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 1}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }
    

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: returns error without product" do
    post "/products/", params: {}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'product' in request body with fields: title description(optional) price quantity images", response["msg"]
  end

  test "create: doesn't save product with empty and/or invalid fields" do
    post "/products/", params: {product: {title: nil, images: nil, price: nil, quantity: nil,}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Title must be provided"
    assert response["msgs"].include? "Images length should be between 1 and 3"
    assert response["msgs"].include? "Price is not a number"
    assert response["msgs"].include? "Quantity is not a number"

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save product with more than 3 images" do
    post "/products/", params: {product: {images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}, {fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}]}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Images length should be between 1 and 3"

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save when price is not integer" do
    post "/products/", params: {product: {price: 300.00}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Price must be an integer"

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save when price is less than 300" do
    post "/products/", params: {product: {price: 299}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Price must be greater than or equal to 300"

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save when quantity is not integer" do
    post "/products/", params: {product: {quantity: 1.00}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Quantity must be an integer"

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save when quantity is less than 1" do
    post "/products/", params: {product: {quantity: 0}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Quantity must be greater than or equal to 1"

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  def product_instance(product_title = "test product") 
    product = Product.new
    product.title = product_title
    product.images = [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}]
    product.price = 300
    product.quantity = 1

    return product
  end
  def category_instance(category_name = "test category") 
    category = Category.new
    category.name = category_name

    return category
  end
  def user_instance(username = "Hasan Abir", email = "test@test.com") 
    user = User.new
    user.username = username
    user.email = email
    user.password = "testtest"

    return user
  end
  def role_instance(name = "ROLE_ADMIN") 
    role = Role.new
    role.name = name

    return role
  end
end