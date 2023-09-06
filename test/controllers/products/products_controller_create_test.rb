require "test_helper"

class ProductsControllerCreateTest < ActionDispatch::IntegrationTest
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

    test "create: creates product" do
        imagekitio = ImageKitIo.client
        
        product = {title: "Product", description: "Lorem", image_files: [upload_image("pianocat.jpeg", "image/jpeg", true), upload_image("jelliecat.jpg", "image/jpeg", true)], price: 300, quantity: 1}

        token = generate_token("admin")

        post "/products/", params: {product: product}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token, "Content-Type" => "multipart/form-data" }

        response = JSON.parse(@response.body)
        assert_equal 200, @response.status

        assert_equal product[:title], response["title"]
        assert response["price"]
        assert response["quantity"]
        assert response["description"]
        assert_equal 2, response["images"].length
        assert response["category_list"]
    
        productsSaved = Product.all
        assert_equal 1, productsSaved.length
        assert_equal 2, Product.first.images.length

        image_ids = response["images"].map do |image| 
            assert image["fileId"]
            assert image["url"]

            image["fileId"]
          end
      
        imagekitio.delete_bulk_files(file_ids: image_ids)
    end

    test "create: doesn't create product when token expires" do
        ENV["ACCESS_EXPIRATION_SECONDS"] = "60"

        token = generate_token("admin")

        travel_to(Time.now + 2.minutes) do
            product = {title: "", description: "Lorem", image_files: [upload_image("pianocat.jpeg", "image/jpeg", true), upload_image("jelliecat.jpg", "image/jpeg", true)], price: 300, quantity: 1}

            post "/products/", params: {product: product}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token, "Content-Type" => "multipart/form-data" }

            response = JSON.parse(@response.body)
            assert_equal 401, @response.status
        end
    end

    test "create: doesn't create product if product params are not provided" do
        token = generate_token("admin")

        post "/products/", params: {}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token, "Content-Type" => "multipart/form-data" }

        response = JSON.parse(@response.body)
        assert_equal 400, @response.status

        assert_equal "Requires 'product' in request body with fields: title description(optional) price quantity image_files", response["msg"]
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end

    test "create: doesn't create product if there is a validation error" do
        token = generate_token("admin")

        product = {description: "Lorem", image_files: [upload_image("windowcat.jpg"), upload_image("jelliecat.jpg")], price: 300, quantity: 1}

        post "/products/", params: {product: product}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token, "Content-Type" => "multipart/form-data" }

        response = JSON.parse(@response.body)
        assert_equal 400, @response.status

        assert response["msgs"].include? "Title must be provided"
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end

    test "create: doesn't create product if not authenticated" do
        product = {title: "Product", description: "Lorem", image_files: [upload_image("windowcat.jpg"), upload_image("jelliecat.jpg")], price: 300, quantity: 1}

        token = generate_token("admin")

        post "/products/", params: {product: product}

        response = JSON.parse(@response.body)
        assert_equal 401, @response.status

        assert_equal "Unauthenticated", response["msg"]
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end

    
    test "create: doesn't create product if insufficient role" do
        product = {title: "Product", description: "Lorem", image_files: [upload_image("windowcat.jpg"), upload_image("jelliecat.jpg")], price: 300, quantity: 1}

        token = generate_token("user")

        post "/products/", params: {product: product}, headers: { "HTTP_AUTHORIZATION" => "Bearer " + token, "Content-Type" => "multipart/form-data" }

        response = JSON.parse(@response.body)
        assert_equal 403, @response.status

        assert_equal "Unauthorized", response["msg"]
    
        productsSaved = Product.all
        assert_equal 0, productsSaved.length
    end
end
