require "test_helper"

class ProductsControllerIndexTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner[:mongoid].start
    Product.create_indexes
  end
    
  teardown do
    DatabaseCleaner[:mongoid].clean
  end  

  test "index: paginated results" do
    x = 1
    while(x <= 10)
      assert product_instance("product: " + x.to_s).save

      x = x + 1
    end

    get "/products"

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal "product: 10", response.first["title"]
    assert_equal "product: 6", response.last["title"]
    assert response.first["_id"]
    assert response.first["images"]
    assert response.first["price"]
    assert response.first["user_rating"]
  end

  test "index: paginated results with both category_id and search text" do
    x = 1
    term = "lorem"
    category = category_instance
    category.save

    while(x <= 10)
      product = product_instance("product: " + x.to_s)

      if x.odd?
        product.title = "product: " + term
        product.category_ids.push(category._id)
      end

      product.save

      x = x + 1
    end

    get "/products?category_id=" + category._id + "&search_term=" + term

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal "product: " + term, response.first["title"]
    assert_equal "product: " + term, response.last["title"]
  end

  test "index: paginated results with search text" do
    x = 1
    term = "lorem"

    while(x <= 10)
      title = "product: " + x.to_s

      if x.odd?
        title = "product: " + term
      end

      product_instance(title).save

      x = x + 1
    end

    get "/products?search_term=" + term

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal "product: " + term, response.first["title"]
    assert_equal "product: " + term, response.last["title"]
  end

  test "index: paginated results from category id" do
    category = category_instance
    category.save

    x = 1
    while(x <= 10)
      product = product_instance("product: " + x.to_s)
      
      if x.odd?
        product.category_ids.push(category._id)
      end

      product.save

      x = x + 1
    end

    get "/products?category_id=" + category._id

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal "product: 9", response.first["title"]
    assert_equal "product: 1", response.last["title"]
  end

  test "index: paginated results next page" do
    x = 1
    next_page = ""
    while(x <= 10)
      product = product_instance("product: " + x.to_s)
      product.save
      product.updated_at = Time.new(product.updated_at.to_s) + (60 * x)
      product.save

      if x == 6
        next_page = product.updated_at
      end

      x = x + 1
    end

    get "/products?next=" + next_page.to_s

    
    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal "product: 5", response.first["title"]
    assert_equal "product: 1", response.last["title"]
  end

  test "index: paginated results next page with both category_id and search text" do
    x = 1
    next_page = ""
    term = "lorem"
    category = category_instance
    category.save

    while(x <= 10)
      product = product_instance("product: " + x.to_s)

      if x.odd?
        product.title = "product: " + term
        product.category_ids.push(category._id)
      end

      product.save
      product.updated_at = Time.new(product.updated_at.to_s) + (60 * x)
      product.save

      if x == 7
        next_page = product.updated_at
      end

      x = x + 1
    end

    get "/products?next=" + next_page.to_s + "&category_id=" + category._id + "&search_term=" + term

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 3, response.length
    assert_equal "product: " + term, response.first["title"]
    assert_equal "product: " + term, response.last["title"]
  end

  test "index: paginated results next page with search text" do
    x = 1
    next_page = ""
    term = "lorem"

    while(x <= 10)
      title = "product: " + x.to_s

      if x.odd?
        title = "product: " + term
      end

      product = product_instance(title)
      product.save
      product.updated_at = Time.new(product.updated_at.to_s) + (60 * x)
      product.save

      if x == 7
        next_page = product.updated_at
      end

      x = x + 1
    end

    get "/products?next=" + next_page.to_s + "&search_term=" + term

    
    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 3, response.length
    assert_equal "product: " + term, response.first["title"]
    assert_equal "product: " + term, response.last["title"]
  end

  test "index: paginated results next page from category_id" do
    category = category_instance
    category.save

    x = 1
    next_page = ""
    while(x <= 10)
      product = product_instance("product: " + x.to_s)

      if x.odd?
        product.category_ids.push(category._id)
      end

      product.save
      product.updated_at = Time.new(product.updated_at.to_s) + (60 * x)
      product.save

      if x == 7
        next_page = product.updated_at
      end

      x = x + 1
    end

    get "/products?next=" + next_page.to_s + "&category_id=" + category._id

    
    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 3, response.length
    assert_equal "product: 5", response.first["title"]
    assert_equal "product: 1", response.last["title"]
  end

  test "index: limited paginated results" do
    limit = 8
    x = 1
    while(x <= 10)
      product_instance("product: " + x.to_s).save

      x = x + 1
    end

    get "/products?limit=" + limit.to_s

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal limit, response.length
  end

  test "index: limited paginated results with both category_id and search text" do
    x = 1
    limit = 3
    term = "lorem"
    category = category_instance
    category.save

    while(x <= 10)
      product = product_instance("product: " + x.to_s)

      if x.odd?
        product.title = "product: " + term
        product.category_ids.push(category._id)
      end

      product.save

      x = x + 1
    end

    get "/products?limit=" + limit.to_s + "&category_id=" + category._id + "&search_term=" + term

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 3, response.length
  end

  test "index: limited paginated results with search text" do
    limit = 3
    x = 1
    term = "lorem"

    while(x <= 10)
      title = "product: " + x.to_s

      if x.odd?
        title = "product: " + term
      end

      product_instance(title).save

      x = x + 1
    end

    get "/products?limit=" + limit.to_s + "&search_term=" + term

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal limit, response.length
  end

  test "index: limited paginated results with category_id" do
    category = category_instance
    category.save

    limit = 3
    x = 1
    while(x <= 10)
      product = product_instance("product: " + x.to_s)
      
      if x.odd?
        product.category_ids.push(category._id)
      end

      product.save

      x = x + 1
    end

    get "/products?limit=" + limit.to_s + "&category_id=" + category._id

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal limit, response.length
  end
end