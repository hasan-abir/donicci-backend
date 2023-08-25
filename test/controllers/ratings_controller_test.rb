require "test_helper"

class RatingsControllerTest < ActionDispatch::IntegrationTest
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

  test "create: creates rating for a product" do
    token = generate_token("admin")

    product = product_instance
    product.save

    score = 3

    post "/ratings", params: {score: score, product_id: product._id}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 200, @response.status

    assert_equal 3, response["average_score"]

    assert_equal 1, Rating.all.length
    assert_equal 1, Product.first.ratings.length
    assert_equal 3, Product.first.user_rating
  end 

  test "create: updates rating and returns average score" do
    token = generate_token("admin")

    product = product_instance
    product.save 

    user = User.where(username: "hasan_abir1999").first

    x = 1
    while(x <= 5)
      rating = rating_instance
      reviewer = user_instance("user_" + x.to_s, "user" + x.to_s + "@test.com")
      role = Role.where(name: "ROLE_USER").first
      reviewer.role_ids.push(role._id)
      reviewer.save
      rating.user_id = reviewer._id
      rating.product_id = product._id

      score = 1

      if [1, 2, 5].include? x
        score = 3
      else
        score = 5
      end

      rating.score = score
      rating.save

      x = x + 1
    end

    score = 3

    post "/ratings", params: {score: score, product_id: product._id}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 200, @response.status

    assert_equal 3.7, response["average_score"]

    assert_equal 6, Rating.all.length
    assert_equal 6, Product.first.ratings.length
    assert_equal 3.7, Product.first.user_rating
  end
  
  test "create: updates rating done by a user without duplicates" do
    token = generate_token("admin")

    product = product_instance
    product.save

    user = User.where(username: "hasan_abir1999").first

    rating = rating_instance
    rating.user_id = user._id
    rating.product_id = product._id
    rating.score = 4
    rating.save

    score = 3

    post "/ratings", params: {score: score, product_id: product._id}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 200, @response.status

    assert_equal score, response["average_score"]

    assert_equal 1, Rating.all.length
    assert_equal 1, Product.first.ratings.length
    assert_equal score, Product.first.user_rating
  end

  test "create: doesn't create rating when product doesn't exist" do
    token = generate_token("admin")

    score = 3

    post "/ratings", params: {score: score, product_id: "123"}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 404, @response.status

    assert_equal "Product not found", response["msg"]

    assert_equal 0, Rating.all.length
  end 

  test "create: doesn't create rating when not authenticated" do
    product = product_instance
    product.save

    score = 3

    post "/ratings", params: {score: score, product_id: product._id}

    response = JSON.parse(@response.body)

    assert_equal 401, @response.status

    assert_equal "Unauthenticated", response["msg"]

    assert_equal 0, Rating.all.length
    assert_equal 0, Product.first.ratings.length
    assert_equal 0, Product.first.user_rating
  end 

  test "create: doesn't create rating when score is invalid" do
    token = generate_token("")

    product = product_instance
    product.save

    score = nil

    post "/ratings", params: {score: score, product_id: product._id}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 400, @response.status

    assert_equal ["Score must be provided", "Score is not a number"], response["msgs"]

    score = 1.5

    post "/ratings", params: {score: score, product_id: product._id}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 400, @response.status

    assert_equal ["Score must be an integer"], response["msgs"]

    score = 0

    post "/ratings", params: {score: score, product_id: product._id}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 400, @response.status

    assert_equal ["Score must be greater than or equal to 1"], response["msgs"]

    score = 6

    post "/ratings", params: {score: score, product_id: product._id}, headers: {"HTTP_AUTHORIZATION": "Bearer " + token}

    response = JSON.parse(@response.body)

    assert_equal 400, @response.status

    assert_equal ["Score must be less than or equal to 5"], response["msgs"]

    assert_equal 0, Rating.all.length
    assert_equal 0, Product.first.ratings.length
    assert_equal 0, Product.first.user_rating
  end 
end
