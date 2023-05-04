require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  teardown do
    Category.delete_all
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
    post "/categories/", params: {category: {name: "Category"}}

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert response["_id"]

    categoriesSaved = Category.all
    assert_equal 1, categoriesSaved.length
  end

  test "create: returns error without category" do
    post "/categories/", params: {}

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'category' in request body", response["msg"]
  end

  test "create: doesn't save category with empty name" do
    post "/categories/", params: {category: {name: nil}}

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Name must be provided"
    assert_equal 400, @response.status

    categoriesSaved = Category.all
    assert_equal 0, categoriesSaved.length
  end

  test "destroy: deletes category" do
    category = category_instance
    category.save

    delete "/categories/" + category._id

    assert_equal 201, @response.status

    categoriesSaved = Category.all
    assert_equal 0, categoriesSaved.length
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

    put "/categories/" + category._id, params: updatedCategory 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal updatedCategory[:category][:name], response["name"]
  end

  test "update: updates category without name" do
    category = category_instance
    category.save

    updatedCategory = {category: {name: nil}}

    put "/categories/" + category._id, params: updatedCategory 
    
    response = JSON.parse(@response.body)

    assert_equal 200, @response.status
    assert_equal category.name, response["name"]
  end
  
  test "update: returns error without category in request body" do
    category = category_instance
    category.save

    updatedCategory = {}

    put "/categories/" + category._id, params: updatedCategory 

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'category' in request body", response["msg"]
  end

  def category_instance(category_name = "test category") 
    category = Category.new
    category.name = category_name

    return category
  end
end
