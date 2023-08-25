require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner[:mongoid].start

    user = user_instance
    
    role_admin = role_instance("role_admin")
    role_admin.save
    role_admin = role_instance("role_moderator")
    role_admin.save
    role_user = role_instance
    role_user.save

    user.role_ids.push(role_admin._id)

    user.save 
  end

  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "get_product_reviews: paginates results" do
    product = product_instance
    product.save

    user = User.where(username: "hasan_abir1999").first

    x = 1

    while(x <= 10)
      review = review_instance("Review " + x.to_s)

      review.user_id = user._id
      review.product_id = product._id

      review.save

      x = x + 1
    end

    assert_equal 10, Review.all.length

    get "/reviews/product/" + product._id

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal user.display_name, response.first["author"]
    assert_not response.first["user_id"]
    assert_equal "Review 10", response.first["description"]
    assert_equal "Review 6", response.last["description"]
  end

  test "get_product_reviews: paginates results next page" do
    product = product_instance
    product.save

    user = User.where(username: "hasan_abir1999").first

    x = 1
    next_page = ""

    while(x <= 10)
      review = review_instance("Review " + x.to_s)

      review.user_id = user._id
      review.product_id = product._id
      review.updated_at = Time.new(product.updated_at.to_s) + (60 * x)

      review.save

      if x == 6
        next_page = review.updated_at
      end

      x = x + 1
    end

    assert_equal 10, Review.all.length

    get "/reviews/product/" + product._id + "?next=" + next_page.to_s

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal user.display_name, response.first["author"]
    assert_not response.first["user_id"]
    assert_equal "Review 5", response.first["description"]
    assert_equal "Review 1", response.last["description"]
  end

  test "get_product_reviews: paginates results with limit" do
    product = product_instance
    product.save

    user = User.where(username: "hasan_abir1999").first

    x = 1

    while(x <= 10)
      review = review_instance("Review " + x.to_s)

      review.user_id = user._id
      review.product_id = product._id

      review.save

      x = x + 1
    end

    assert_equal 10, Review.all.length

    limit = 3

    get "/reviews/product/" + product._id + "?limit=" + limit.to_s

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 3, response.length
  end

  test "get_product_reviews: doesn't paginate results if product not found" do
    product = product_instance
    product.save

    user = User.where(username: "hasan_abir1999").first

    x = 1
    next_page = ""

    while(x <= 10)
      review = review_instance("Review " + x.to_s)

      review.user_id = user._id
      review.product_id = product._id
      review.updated_at = Time.new(product.updated_at.to_s) + (60 * x)

      review.save

      if x == 6
        next_page = review.updated_at
      end

      x = x + 1
    end

    assert_equal 10, Review.all.length

    get "/reviews/product/123" + "?next=" + next_page.to_s

    response = JSON.parse(@response.body)
    assert_equal 404, @response.status
    assert_equal "Product not found", response["msg"]
  end

  test "create: creates a review" do
    token = generate_token("user")

    product = product_instance
    product.save

    reviewBody = "Lorem ipsum"

    post "/reviews/", params: {product_id: product._id, description: reviewBody}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 200, @response.status
    assert_equal reviewBody, response["description"]
    assert response["_id"]
    assert_equal "Hasan Abir", response["author"]

    assert_equal 1, Review.all.length
  end

  test "create: doesn't create a review if not authenticated" do
    product = product_instance
    product.save

    reviewBody = "Lorem ipsum"

    post "/reviews/", params: {product_id: product._id, description: reviewBody}

    response = JSON.parse(@response.body)

    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]

    assert_equal 0, Review.all.length
  end

  test "create: doesn't create a review if product not found" do
    token = generate_token("user")

    reviewBody = "Lorem ipsum"

    post "/reviews/", params: {product_id: "123", description: reviewBody}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 404, @response.status
    assert_equal "Product not found", response["msg"]

    assert_equal 0, Review.all.length
  end

  test "create: doesn't create a review if description is invalid" do
    token = generate_token("user")

    product = product_instance
    product.save

    reviewBody = nil

    post "/reviews/", params: {product_id: product._id, description: reviewBody}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 400, @response.status
    assert_equal ["Description must be provided"], response["msgs"]

    assert_equal 0, Review.all.length
  end

  test "destroy: deletes a review" do
    token = generate_token("user")

    product = product_instance
    product.save

    user = User.where(username: "hasan_abir1999").first

    review = review_instance

    review.user_id = user._id
    review.product_id = product._id

    review.save

    assert_equal 1, Review.all.length

    delete "/reviews/" + review._id, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    assert_equal 201, @response.status

    assert_equal 0, Review.all.length
  end

  test "destroy: doesn't delete a review if not authenticated" do
    product = product_instance
    product.save

    user = User.where(username: "hasan_abir1999").first

    review = review_instance

    review.user_id = user._id
    review.product_id = product._id

    review.save

    assert_equal 1, Review.all.length

    delete "/reviews/" + review._id

    response = JSON.parse(@response.body)

    assert_equal 401, @response.status
    assert_equal "Unauthenticated", response["msg"]

    assert_equal 1, Review.all.length
  end

  test "destroy: doesn't delete a review if not author" do
    token = generate_token("user")

    product = product_instance
    product.save

    user = user_instance("user_test123", "usertest123@test.com")
    role = Role.where(name: "ROLE_USER").first
    user.role_ids.push(role._id)
    user.save

    review = review_instance

    review.user_id = user._id
    review.product_id = product._id

    review.save

    assert_equal 1, Review.all.length

    delete "/reviews/" + review._id, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 403, @response.status
    assert_equal "Unauthorized", response["msg"]

    assert_equal 1, Review.all.length
  end

  test "destroy: doesn't delete a review if not found" do
    token = generate_token("user")

    delete "/reviews/123", headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)
    assert_equal 404, @response.status
    assert_equal "Review not found", response["msg"]

    assert_equal 0, Review.all.length
  end

end
