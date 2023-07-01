require "test_helper"

class ProductsControllerCreateTest < ActionDispatch::IntegrationTest
    setup do
        DatabaseCleaner[:mongoid].start

        user = user_instance
        
        role_admin = role_instance("ROLE_ADMIN")
        role_admin.save
        role_mod = role_instance("ROLE_MODERATOR")
        role_mod.save
        role_user = role_instance("ROLE_USER")
        role_user.save

        user.role_ids.push(role_admin._id)

        user.save
    end

    teardown do
        DatabaseCleaner[:mongoid].clean
    end

    test "create: creates product" do
        product = {title: "Product", description: "Lorem", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 1, user_rating: 0}

        token = generate_token("admin")

        post "/products/", params: {product: product}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

        response = JSON.parse(@response.body)
        assert_equal 200, @response.status

        assert_equal product[:title], response["title"]
        assert response["price"]
        assert response["quantity"]
        assert response["user_rating"]
        assert response["description"]
        assert response["images"]
        assert response["category_list"]
    
        productsSaved = Product.all
        assert_equal 1, productsSaved.length
    end

    test "create: creates product as moderator" do
        product = {title: "Product", description: "Lorem", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 1, user_rating: 0}

        token = generate_token("mod")

        post "/products/", params: {product: product}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

        response = JSON.parse(@response.body)
        assert_equal 200, @response.status

        assert_equal product[:title], response["title"]
        assert response["price"]
        assert response["quantity"]
        assert response["user_rating"]
        assert response["description"]
        assert response["images"]
        assert response["category_list"]
    
        productsSaved = Product.all
        assert_equal 1, productsSaved.length
    end

    test "create: doesn't create product unauthenticated" do
        post "/products/" 

        response = JSON.parse(@response.body)

        assert_equal 401, @response.status
        assert_equal "Unauthenticated", response["msg"]
    end

    test "create: doesn't create product as user" do
        token = generate_token("user")

        post "/products/", headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

        response = JSON.parse(@response.body)

        assert_equal 403, @response.status
        assert_equal "Unauthorized", response["msg"]
    end

    test "create: doesn't create product without product" do
        token = generate_token("admin")

        post "/products/" , headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

        response = JSON.parse(@response.body)

        assert_equal 400, @response.status
        assert_equal "Requires 'product' in request body with fields: title description(optional) price quantity user_rating images", response["msg"]
    end

    test "create: doesn't save product with empty and/or invalid fields" do
        token = generate_token("admin")

        post "/products/", params: {product: {title: nil, images: nil, price: nil, quantity: nil, user_rating: nil}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Title must be provided"
        assert response["msgs"].include? "Images length should be between 1 and 3"
        assert response["msgs"].include? "Price is not a number"
        assert response["msgs"].include? "Quantity is not a number"
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end
    
    test "create: doesn't save product with more than 3 images" do
        token = generate_token("admin")

        post "/products/", params: {product: {images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}, {fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}]}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Images length should be between 1 and 3"
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end
    
    test "create: doesn't save when price is not integer" do
        token = generate_token("admin")

        post "/products/", params: {product: {price: 300.00}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Price must be an integer"
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end
    
    test "create: doesn't save when price is less than 300" do
        token = generate_token("admin")

        post "/products/", params: {product: {price: 299}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Price must be greater than or equal to 300"
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end
    
    test "create: doesn't save when quantity is not integer" do
        token = generate_token("admin")

        post "/products/", params: {product: {quantity: 1.00}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Quantity must be an integer"
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end
    
    test "create: doesn't save when quantity is less than 1" do
        token = generate_token("admin")

        post "/products/", params: {product: {quantity: 0}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Quantity must be greater than or equal to 1"
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end
    
    test "create: doesn't save when user_rating is less than 0" do
        token = generate_token("admin")

        post "/products/", params: {product: {user_rating: -1}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "User rating must be greater than or equal to 0"
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end
    
    test "create: doesn't save when user_rating is greater than 5" do
        token = generate_token("admin")

        post "/products/", params: {product: {user_rating: 5.5}}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "User rating must be less than or equal to 5"
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end
end
