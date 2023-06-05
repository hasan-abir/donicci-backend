require "test_helper"

class ProductsControllerUpdateTest < ActionDispatch::IntegrationTest
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

  test "update: updates product" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}], price: 350, quantity: 2}}

    put "/products/" + product._id, params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal updatedProduct[:product][:title], response["title"]
    assert_equal updatedProduct[:product][:images].length, response["images"].length
    assert_equal updatedProduct[:product][:price], response["price"]
    assert_equal updatedProduct[:product][:quantity], response["quantity"]
  end

  test "update: updates product as moderator" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}], price: 350, quantity: 2}}

    put "/products/" + product._id, params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @mod_token }

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal updatedProduct[:product][:title], response["title"]
    assert_equal updatedProduct[:product][:images].length, response["images"].length
    assert_equal updatedProduct[:product][:price], response["price"]
    assert_equal updatedProduct[:product][:quantity], response["quantity"]
  end

  test "update: doesn't update product without authentication" do
    product = product_instance
    product.save

    put "/products/" + product._id

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]
  end

  test "update: doesn't update product without permission" do
    product = product_instance
    product.save

    put "/products/" + product._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]
  end

  test "update: updates product with empty and/or invalid fields" do
    product = product_instance
    product.save

    updatedProduct = {product: {images: nil, title: nil, description: nil, price: nil, quantity: nil}}

    put "/products/" + product._id, params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token } 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal product.title, response["title"]
    assert_equal product.images.length, response["images"].length
    assert_equal product.price, response["price"]
    assert_equal product.quantity, response["quantity"]
  end

  test "update: returns error without product in request body" do
    product = product_instance
    product.save

    updatedProduct = {}

    put "/products/" + product._id, params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'product' in request body with fields: title(optional) description(optional) price(optional) quantity(optional) images(optional)", response["msg"]
  end

  test "update: doesn't update product with more than 3 images" do
    product = product_instance
    product.save

    updatedProduct = {product: {images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}, {fileId: "6", url: "https://hasanabir.netlify.app/"}]}}

    put "/products/" + product._id, params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Images length should be between 1 and 3"
  end

  test "update: doesn't update when price is not integer" do
    product = product_instance
    product.save

    updatedProduct = {product: {price: 350.00}}

    put "/products/" + product._id, params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Price must be an integer"
  end

  test "update: doesn't update when price is less than 300" do
    product = product_instance
    product.save

    updatedProduct = {product: {price: -350}}

    put "/products/" + product._id, params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Price must be greater than or equal to 300"
  end

  test "update: doesn't update when quantity is not integer" do
    product = product_instance
    product.save

    updatedProduct = {product: {quantity: 2.00}}

    put "/products/" + product._id, params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Quantity must be an integer"
  end

  test "update: doesn't update when quantity is less than 1" do
    product = product_instance
    product.save

    updatedProduct = {product: {quantity: -2}}

    put "/products/" + product._id, params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert response["msgs"].include? "Quantity must be greater than or equal to 1"
  end
 

  def product_instance(product_title = "test product") 
    product = Product.new
    product.title = product_title
    product.images = [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}]
    product.price = 300
    product.quantity = 1

    product
  end
  def category_instance(category_name = "test category") 
    category = Category.new
    category.name = category_name

    category
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