require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
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

  test "add_categories: adds categories to product" do
    category1 = category_instance("category 1")
    category2 = category_instance("category 2")
    category1.save
    category2.save
    product = product_instance
    product.save

    category_ids = []
    category_ids.push(category1._id)
    category_ids.push(category2._id)

    updatedProduct = {category_ids: category_ids}

    put "/products/" + product._id + "/categories", params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token } 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 2, response["category_list"].length
    assert_equal category1.name, response["category_list"][0]["name"]
    assert_equal category2.name, response["category_list"][1]["name"]
  end

  test "add_categories: adds categories to product as moderator" do
    category1 = category_instance("category 1")
    category2 = category_instance("category 2")
    category1.save
    category2.save
    product = product_instance
    product.save

    category_ids = []
    category_ids.push(category1._id)
    category_ids.push(category2._id)

    updatedProduct = {category_ids: category_ids}

    put "/products/" + product._id + "/categories", params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @mod_token } 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 2, response["category_list"].length
    assert_equal category1.name, response["category_list"][0]["name"]
    assert_equal category2.name, response["category_list"][1]["name"]
  end

  test "add_categories: doesn't add categories to product without authentication" do
    category1 = category_instance("category 1")
    category2 = category_instance("category 2")
    category1.save
    category2.save
    product = product_instance
    product.save

    category_ids = []
    category_ids.push(category1._id)
    category_ids.push(category2._id)

    updatedProduct = {category_ids: category_ids}

    put "/products/" + product._id + "/categories", params: updatedProduct

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]
  end

  test "add_categories: doesn't add categories to product without permission" do
    category1 = category_instance("category 1")
    category2 = category_instance("category 2")
    category1.save
    category2.save
    product = product_instance
    product.save

    category_ids = []
    category_ids.push(category1._id)
    category_ids.push(category2._id)

    updatedProduct = {category_ids: category_ids}

    put "/products/" + product._id + "/categories", params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token } 

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]
  end

  test "add_categories: returns error without category_ids" do
    product = product_instance
    product.save

    put "/products/" + product._id + "/categories", params: {}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'category_ids' array in request body", response["msg"]
  end

  test "remove_categories: removes categories from product" do
    category1 = category_instance("category 1")
    category2 = category_instance("category 2")
    category3 = category_instance("category 3")
    category1.save
    category2.save
    category3.save
    product = product_instance
    product.category_ids.push(category1._id)
    product.category_ids.push(category2._id)
    product.save

    category_ids = []
    category_ids.push(category2._id)

    updatedProduct = {category_ids: category_ids}

    put "/products/" + product._id + "/categories/remove", params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token } 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 1, response["category_list"].length
    assert_equal category1.name, response["category_list"][0]["name"]
  end

  test "remove_categories:  doesn't remove categories from product without authentication" do
    category1 = category_instance("category 1")
    category2 = category_instance("category 2")
    category3 = category_instance("category 3")
    category1.save
    category2.save
    category3.save
    product = product_instance
    product.category_ids.push(category1._id)
    product.category_ids.push(category2._id)
    product.save

    category_ids = []
    category_ids.push(category2._id)

    updatedProduct = {category_ids: category_ids}

    put "/products/" + product._id + "/categories/remove", params: updatedProduct

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]
  end

  test "remove_categories: removes categories from product as moderator" do
    category1 = category_instance("category 1")
    category2 = category_instance("category 2")
    category3 = category_instance("category 3")
    category1.save
    category2.save
    category3.save
    product = product_instance
    product.category_ids.push(category1._id)
    product.category_ids.push(category2._id)
    product.save

    category_ids = []
    category_ids.push(category2._id)

    updatedProduct = {category_ids: category_ids}

    put "/products/" + product._id + "/categories/remove", params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @mod_token } 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 1, response["category_list"].length
    assert_equal category1.name, response["category_list"][0]["name"]
  end

  test "remove_categories: doesn't remove categories from product without permission" do
    category1 = category_instance("category 1")
    category2 = category_instance("category 2")
    category3 = category_instance("category 3")
    category1.save
    category2.save
    category3.save
    product = product_instance
    product.category_ids.push(category1._id)
    product.category_ids.push(category2._id)
    product.save

    category_ids = []
    category_ids.push(category2._id)

    updatedProduct = {category_ids: category_ids}

    put "/products/" + product._id + "/categories/remove", params: updatedProduct, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token } 

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]
  end

  test "remove_categories: returns error without category_ids" do
    product = product_instance
    product.save

    put "/products/" + product._id + "/categories/remove", params: {}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'category_ids' array in request body", response["msg"]
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