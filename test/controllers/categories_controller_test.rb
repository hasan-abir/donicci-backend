require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner[:mongoid].start

    user = user_instance
    
    role_admin = role_instance("role_admin")
    role_admin.save
    role_mod = role_instance("role_moderator")
    role_mod.save
    role_user = role_instance
    role_user.save

    user.role_ids.push(role_admin._id)

    user.save
  end

  teardown do
    DatabaseCleaner[:mongoid].clean
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
    token = generate_token("admin")

    post "/categories/", params: {category: {name: "Category"}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

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
    token = generate_token

    post "/categories/", params: {category: {name: "Category"}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]

    categoriesSaved = Category.all
    assert_equal 0, categoriesSaved.length
  end

  test "create: returns error without category" do
    token = generate_token("admin")

    post "/categories/", params: {}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'category' in request body", response["msg"]
  end

  test "create: doesn't save category if validation error" do
    token = generate_token("admin")

    post "/categories/", params: {category: {name: nil}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Name must be provided"
    assert_equal 400, @response.status

    categoriesSaved = Category.all
    assert_equal 0, categoriesSaved.length
  end

  test "destroy: deletes category" do
    category = category_instance
    category.save

    token = generate_token("admin")

    delete "/categories/" + category._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

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

    token = generate_token

    delete "/categories/" + category._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

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

    token = generate_token("admin")

    put "/categories/" + category._id, params: updatedCategory, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

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

    token = generate_token

    put "/categories/" + category._id, params: updatedCategory, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

    response = JSON.parse(@response.body)
    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]
  end

  test "update: updates category if validation error" do
    category = category_instance
    category.save

    updatedCategory = {category: {name: nil}}

    token = generate_token("admin")

    put "/categories/" + category._id, params: updatedCategory, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token } 
    
    response = JSON.parse(@response.body)

    assert_equal 200, @response.status
    assert_equal category.name, response["name"]
  end
  
  test "update: returns error without category in request body" do
    category = category_instance
    category.save

    updatedCategory = {}

    token = generate_token("admin")
    
    put "/categories/" + category._id, params: updatedCategory, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token } 

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'category' in request body", response["msg"]
  end
end
