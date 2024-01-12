require "test_helper"

class ProductsControllerUpdateTest < ActionDispatch::IntegrationTest
    setup do
        DatabaseCleaner[:mongoid].start

        user = user_instance
        
        role_admin = role_instance("ROLE_ADMIN")
        role_admin.save
        role_user = role_instance("ROLE_USER")
        role_user.save

        user.role_ids.push(role_admin._id)

        user.save
    end

    teardown do
        DatabaseCleaner[:mongoid].clean
    end

    test "update: updates product" do
        imagekitio = ImageKitIo.client

        product = product_instance
        product.upload_images_save_details
        product.save

        updatedProduct = {title: "Updated product", image_files: [upload_image("pianocat.jpeg", "image/jpeg", true), upload_image("peekingcat.jpeg", "image/jpeg", true)], price: 350, quantity: 2}

        token = generate_token("admin")

        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

        response = JSON.parse(@response.body)
        assert_equal 200, @response.status


        assert_equal updatedProduct[:title], response["title"]
        assert_equal updatedProduct[:image_files].length, response["images"].length
        assert_equal updatedProduct[:price], response["price"]
        assert_equal updatedProduct[:quantity], response["quantity"]
        assert response["category_list"]
        assert response["user_rating"]

        image_ids = response["images"].map do |image| 
            assert image["fileId"]
            assert image["url"]

            image["fileId"]
          end
      
        imagekitio.delete_bulk_files(file_ids: image_ids)
    end

    test "update: doesn't update product unauthenticated" do
        product = product_instance
        product.save

        put "/products/" + product._id

        response = JSON.parse(@response.body)

        assert_equal 401, @response.status
        assert_equal "No token provided", response["msg"]
    end

    test "update: doesn't update product unauthorized" do
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
        assert_equal "Requires 'product' in request body with fields: title(optional) description(optional) price(optional) quantity(optional) user_rating(optional) image_files(optional)", response["msg"]
    end

    test "update: doesn't update product with validation errors" do
        product = product_instance
        product.save
    
        updatedProduct = {image_files: [upload_image("pianocat.jpeg", nil, true), upload_image("peekingcat.jpeg", nil, true)], price: 200, quantity: 2}

        token = generate_token("admin")
    
        put "/products/" + product._id, params: {product: updatedProduct}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token } 
    
        response = JSON.parse(@response.body)
        assert_equal 400, @response.status
        assert response["msgs"].include? "Price must be greater than or equal to 300"
    end
end
