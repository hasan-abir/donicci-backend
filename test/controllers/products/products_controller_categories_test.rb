require "test_helper"

class ProductsControllerCategoriesTest < ActionDispatch::IntegrationTest
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

    test "add_categories: adds categories to product" do
        category1 = category_instance("category 1")
        category2 = category_instance("category 2")
        category1.save
        category2.save
        product = product_instance
        product.save
    
        category_ids = []
        category_ids.push(category1._id)
        category_ids.push(category2._id)
    
        token = generate_token("admin")

        put "/products/" + product._id + "/categories", params: {category_ids: category_ids}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)

        assert_equal 200, @response.status
        assert_equal 2, response["category_list"].length
        assert_equal category1.name, response["category_list"][0]["name"]
        assert_equal category2.name, response["category_list"][1]["name"]
    end

    test "add_categories: adds categories to product as moderator" do
        category1 = category_instance("category 1")
        category2 = category_instance("category 2")
        category1.save
        category2.save
        product = product_instance
        product.save
    
        category_ids = []
        category_ids.push(category1._id)
        category_ids.push(category2._id)
    
        token = generate_token("mod")

        put "/products/" + product._id + "/categories", params: {category_ids: category_ids}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)

        assert_equal 200, @response.status
        assert_equal 2, response["category_list"].length
        assert_equal category1.name, response["category_list"][0]["name"]
        assert_equal category2.name, response["category_list"][1]["name"]
    end

    test "add_categories: doesn't add categories to product unauthenticated" do
        product = product_instance
        product.save

        put "/products/" + product._id + "/categories"
        response = JSON.parse(@response.body)

        assert_equal 401, @response.status
        assert_equal "Unauthenticated", response["msg"]
    end

    test "add_categories: doesn't add categories to product as user" do
        product = product_instance
        product.save
    
        token = generate_token("user")

        put "/products/" + product._id + "/categories", headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)

        assert_equal 403, @response.status
        assert_equal "Unauthorized", response["msg"]
    end

    test "add_categories: doesn't add categories to product without category_ids" do
        product = product_instance
        product.save
    
        token = generate_token("admin")

        put "/products/" + product._id + "/categories", headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)

        assert_equal 400, @response.status
        assert_equal "Requires 'category_ids' array in request body", response["msg"]
    end

    test "remove_categories: remove categories from product" do
        category1 = category_instance("category 1")
        category2 = category_instance("category 2")
        category3 = category_instance("category 3")
        category1.save
        category2.save
        category3.save
        product = product_instance
        product.category_ids.push(category1._id)
        product.category_ids.push(category2._id)
        product.save

        category_ids = []
        category_ids.push(category2._id)
    
        token = generate_token("admin")

        put "/products/" + product._id + "/categories/remove", params: {category_ids: category_ids}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)

        assert_equal 200, @response.status
        assert_equal 1, response["category_list"].length
        assert_equal category1.name, response["category_list"][0]["name"]
    end

    test "remove_categories: remove categories from product as moderator" do
        category1 = category_instance("category 1")
        category2 = category_instance("category 2")
        category3 = category_instance("category 3")
        category1.save
        category2.save
        category3.save
        product = product_instance
        product.category_ids.push(category1._id)
        product.category_ids.push(category2._id)
        product.save

        category_ids = []
        category_ids.push(category2._id)
        
        token = generate_token("admin")

        put "/products/" + product._id + "/categories/remove", params: {category_ids: category_ids}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)

        assert_equal 200, @response.status
        assert_equal 1, response["category_list"].length
        assert_equal category1.name, response["category_list"][0]["name"]
    end

    test "remove_categories: doesn't remove categories from product unauthenticated" do
        product = product_instance
        product.save

        put "/products/" + product._id + "/categories/remove"
        response = JSON.parse(@response.body)

        assert_equal 401, @response.status
        assert_equal "Unauthenticated", response["msg"]
    end

    test "remove_categories: doesn't remove categories from product as user" do
        product = product_instance
        product.save
    
        token = generate_token("user")

        put "/products/" + product._id + "/categories/remove", headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)

        assert_equal 403, @response.status
        assert_equal "Unauthorized", response["msg"]
    end

    test "remove_categories: doesn't remove categories from product without category_ids" do
        product = product_instance
        product.save
    
        token = generate_token("admin")

        put "/products/" + product._id + "/categories/remove", headers: { "HTTP_AUTHORIZATION" => "Bearer " + token }
    
        response = JSON.parse(@response.body)

        assert_equal 400, @response.status
        assert_equal "Requires 'category_ids' array in request body", response["msg"]
    end
end
