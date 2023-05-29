require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
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
    Category.delete_all
    User.delete_all
    Role.delete_all
  end  

  test "index: paginated results" do
    x = 1
    while(x <= 10)
      category_instance("category: " + x.to_s).save

      x = x + 1
    end

    get "/categories"

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal "category: 10", response.first["name"]
    assert_equal "category: 6", response.last["name"]
  end

  
  test "index: paginated results next page" do
    x = 1
    nextPage = ""
    while(x <= 10)
      category = category_instance("category: " + x.to_s)
      category.save
      category.updated_at = Time.new(category.updated_at.to_s) + (60 * x)
      category.save

      if x == 6
        nextPage = category.updated_at
      end

      x = x + 1
    end

    get "/categories?next=" + nextPage.to_s

    
    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal "category: 5", response[0]["name"]
    assert_equal "category: 1", response.last["name"]
  end

  test "index: limited paginated results" do
    limit = 8
    x = 1
    while(x <= 10)
      category_instance("category: " + x.to_s).save

      x = x + 1
    end

    get "/categories?limit=" + limit.to_s

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal limit, response.length
  end

  test "show: finds one" do
    category = category_instance
    category.save
    
    get "/categories/" + category._id

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal category[:name], response["name"]
  end

  test "show: 404 when not found" do
    get "/categories/" + "123"

    response = JSON.parse(@response.body)
    assert_equal response["msg"], "Category not found"
    assert_equal 404, @response.status
  end

  test "create: saves category" do
    post "/categories/", params: {category: {name: "Category"}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert response["_id"]

    categoriesSaved = Category.all
    assert_equal 1, categoriesSaved.length
  end

  test "create: saves category as a moderator" do
    post "/categories/", params: {category: {name: "Category"}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @mod_token }

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert response["_id"]

    categoriesSaved = Category.all
    assert_equal 1, categoriesSaved.length
  end

  test "create: doesn't save category without authentication" do
    post "/categories/", params: {category: {name: "Category"}}

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]

    categoriesSaved = Category.all
    assert_equal 0, categoriesSaved.length
  end

  test "create: doesn't save category without permission" do
    post "/categories/", params: {category: {name: "Category"}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]

    categoriesSaved = Category.all
    assert_equal 0, categoriesSaved.length
  end

  test "create: returns error without category" do
    post "/categories/", params: {}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'category' in request body", response["msg"]
  end

  test "create: doesn't save category with empty name" do
    post "/categories/", params: {category: {name: nil}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Name must be provided"
    assert_equal 400, @response.status

    categoriesSaved = Category.all
    assert_equal 0, categoriesSaved.length
  end

  test "destroy: deletes category" do
    category = category_instance
    category.save

    delete "/categories/" + category._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    assert_equal 201, @response.status

    categoriesSaved = Category.all
    assert_equal 0, categoriesSaved.length
  end

  test "destroy: deletes category as moderator" do
    category = category_instance
    category.save

    delete "/categories/" + category._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @mod_token }

    assert_equal 201, @response.status

    categoriesSaved = Category.all
    assert_equal 0, categoriesSaved.length
  end

  test "destroy: doesn't delete category without authentication" do
    category = category_instance
    category.save

    delete "/categories/" + category._id

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]

    categoriesSaved = Category.all
    assert_equal 1, categoriesSaved.length
  end

  test "destroy: doesn't delete category without permission" do
    category = category_instance
    category.save

    delete "/categories/" + category._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]

    categoriesSaved = Category.all
    assert_equal 1, categoriesSaved.length
  end

  test "destroy: 404 when not found" do
    delete "/categories/" + "123"

    response = JSON.parse(@response.body)
    assert_equal response["msg"], "Category not found"
    assert_equal 404, @response.status
  end

  test "update: updates category" do
    category = category_instance
    category.save

    updatedCategory = {category: {name: "Updated category"}}

    put "/categories/" + category._id, params: updatedCategory, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token }

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal updatedCategory[:category][:name], response["name"]
  end

  test "update: updates category as moderator" do
    category = category_instance
    category.save

    updatedCategory = {category: {name: "Updated category"}}

    put "/categories/" + category._id, params: updatedCategory, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @mod_token }

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal updatedCategory[:category][:name], response["name"]
  end

  test "update: doesn't update category without authentication" do
    category = category_instance
    category.save

    updatedCategory = {category: {name: "Updated category"}}

    put "/categories/" + category._id, params: updatedCategory

    response = JSON.parse(@response.body)
    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]
  end

  test "update: doesn't update category without permission" do
    category = category_instance
    category.save

    updatedCategory = {category: {name: "Updated category"}}

    put "/categories/" + category._id, params: updatedCategory, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @user_token }

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]
  end

  test "update: updates category without name" do
    category = category_instance
    category.save

    updatedCategory = {category: {name: nil}}

    put "/categories/" + category._id, params: updatedCategory, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token } 
    
    response = JSON.parse(@response.body)

    assert_equal 200, @response.status
    assert_equal category.name, response["name"]
  end
  
  test "update: returns error without category in request body" do
    category = category_instance
    category.save

    updatedCategory = {}

    put "/categories/" + category._id, params: updatedCategory, headers: { "HTTP_AUTHORIZATION" => "Bearer " + @admin_token } 

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'category' in request body", response["msg"]
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
