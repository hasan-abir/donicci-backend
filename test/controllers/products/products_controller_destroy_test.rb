require "test_helper"

class ProductsControllerDestroyTest < ActionDispatch::IntegrationTest
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

  test "destroy: deletes product" do
    product = product_instance
    product.save

    delete "/products/" + product._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    assert_equal 201, @response.status

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "destroy: deletes product as moderator" do
    product = product_instance
    product.save

    delete "/products/" + product._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @mod_token }

    assert_equal 201, @response.status

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "destroy: doesn't delete product without authentication" do
    product = product_instance
    product.save

    delete "/products/" + product._id

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]

    productsSaved = Product.all
    assert_equal 1, productsSaved.length
  end

  test "destroy: doesn't delete product without permission" do
    product = product_instance
    product.save

    delete "/products/" + product._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]

    productsSaved = Product.all
    assert_equal 1, productsSaved.length
  end

  test "destroy: 404 when not found" do
    delete "/products/" + "123"

    response = JSON.parse(@response.body)
    assert_equal 404, @response.status
    assert_equal response["msg"], "Product not found"
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