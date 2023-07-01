require "test_helper"

class ProductsControllerShowTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner[:mongoid].start
  end

  teardown do
    DatabaseCleaner[:mongoid].clean
  end  

  test "show: finds one" do
    product = product_instance
    product.save
    
    get "/products/" + product._id

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal product[:title], response["title"]
    assert response["price"]
    assert response["quantity"]
    assert response["user_rating"]
    assert response["description"]
    assert response["images"]
    assert response["category_list"]
  end

  test "show: finds one with categories" do
    category1 = category_instance("category 1")
    assert category1.save
    category2 = category_instance("category 2")
    assert category2.save
    product = product_instance
    product.category_ids.push(category1._id)
    product.category_ids.push(category2._id)
    product.save
    
    get "/products/" + product._id

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 2, response["category_list"].length
    assert_equal category1.name, response["category_list"][0]["name"]
    assert_equal category2.name, response["category_list"][1]["name"]
  end

  test "show: 404 when not found" do
    get "/products/" + "123"

    response = JSON.parse(@response.body)
    assert_equal response["msg"], "Product not found"
    assert_equal 404, @response.status
  end
end