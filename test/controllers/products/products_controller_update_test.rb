require "test_helper"

class ProductsControllerUpdateTest < ActionDispatch::IntegrationTest
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

    test "update: updates product" do
        product = product_instance
        product.save

        updatedProduct = {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}], price: 350, quantity: 2}

        token = generate_token("admin")

        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

        response = JSON.parse(@response.body)
        assert_equal 200, @response.status



        assert_equal updatedProduct[:title], response["title"]
        assert_equal updatedProduct[:images].length, response["images"].length
        assert_equal updatedProduct[:price], response["price"]
        assert_equal updatedProduct[:quantity], response["quantity"]
        assert response["category_list"]
    end

    test "update: updates product as moderator" do
        product = product_instance
        product.save

        updatedProduct = {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}], price: 350, quantity: 2}

        token = generate_token("mod")

        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

        response = JSON.parse(@response.body)
        assert_equal 200, @response.status



        assert_equal updatedProduct[:title], response["title"]
        assert_equal updatedProduct[:images].length, response["images"].length
        assert_equal updatedProduct[:price], response["price"]
        assert_equal updatedProduct[:quantity], response["quantity"]
        assert response["category_list"]
    end

    test "update: doesn't update product unauthenticated" do
        product = product_instance
        product.save

        put "/products/" + product._id

        response = JSON.parse(@response.body)

        assert_equal 401, @response.status
        assert_equal "Unauthenticated", response["msg"]
    end

    test "update: doesn't update product as user" do
        product = product_instance
        product.save

        token = generate_token("user")

        put "/products/" + product._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

        response = JSON.parse(@response.body)

        assert_equal 403, @response.status
        assert_equal "Unauthorized", response["msg"]
    end

    test "update: doesn't update product without product" do
        product = product_instance
        product.save

        token = generate_token("admin")

        put "/products/" + product._id, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

        response = JSON.parse(@response.body)

        assert_equal 400, @response.status
        assert_equal "Requires 'product' in request body with fields: title(optional) description(optional) price(optional) quantity(optional) user_rating(optional) images(optional)", response["msg"]
    end

    test "update: updates product with empty and/or invalid fields" do
        product = product_instance
        product.save
    
        updatedProduct = {images: nil, title: nil, description: nil, price: nil, quantity: nil}

        token = generate_token("admin")
    
        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token } 
    
        response = JSON.parse(@response.body)
        assert_equal 200, @response.status
        assert_equal product.title, response["title"]
        assert_equal product.images.length, response["images"].length
        assert_equal product.price, response["price"]
        assert_equal product.quantity, response["quantity"]
    end

    test "update: doesn't update product with more than 3 images" do
        product = product_instance
        product.save
    
        updatedProduct = {images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}, {fileId: "6", url: "https://hasanabir.netlify.app/"}]}
    
        token = generate_token("admin")

        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Images length should be between 1 and 3"
    end
    
    test "update: doesn't update when price is not integer" do
        product = product_instance
        product.save
    
        updatedProduct = {price: 350.00}

        token = generate_token("admin")
    
        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Price must be an integer"
    end
    
    test "update: doesn't update when price is less than 300" do
        product = product_instance
        product.save
    
        updatedProduct = {price: -350}
    
        token = generate_token("admin")

        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Price must be greater than or equal to 300"
    end
    
    test "update: doesn't update when quantity is not integer" do
        product = product_instance
        product.save
    
        updatedProduct = {quantity: 2.00}
    
        token = generate_token("admin")

        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Quantity must be an integer"
    end
    
    test "update: doesn't update when quantity is less than 1" do
        product = product_instance
        product.save
    
        updatedProduct = {quantity: -2}
    
        token = generate_token("admin")

        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Quantity must be greater than or equal to 1"
    end
    
    test "update: doesn't update when user_rating is less than 0" do
        product = product_instance
        product.save
    
        updatedProduct = {user_rating: -1}
    
        token = generate_token("admin")

        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "User rating must be greater than or equal to 0"
    end
    
    test "update: doesn't update when user_rating is greater than 5" do
        product = product_instance
        product.save
    
        updatedProduct = {user_rating: 5.5}
    
        token = generate_token("admin")

        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "User rating must be less than or equal to 5"
    end
end
