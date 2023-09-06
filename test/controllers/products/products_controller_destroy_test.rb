require "test_helper"

class ProductsControllerDestroyTest < ActionDispatch::IntegrationTest
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

    test "destroy: destroys product" do
        product = product_instance
        product.upload_images_save_details
        product.save

        token = generate_token("admin")

        delete "/products/" + product._id,  headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }

        assert_equal 201, @response.status
    end

    test "destroy: doesn't destroy product if not authenticated" do
        delete "/products/" + "123"

        response = JSON.parse(@response.body)

        assert_equal 401, @response.status
        assert_equal "Unauthenticated", response["msg"]
    end

    test "destroy: doesn't destroy product if insufficient role" do
        token = generate_token("user")

        delete "/products/" + "123", headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
        
        response = JSON.parse(@response.body)

        assert_equal 403, @response.status
        assert_equal "Unauthorized", response["msg"]
    end

    test "destroy: 404 when not found" do
        token = generate_token("admin")

        delete "/products/" + "123", headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)
        assert_equal 404, @response.status
        assert_equal response["msg"], "Product not found"
    end
end
