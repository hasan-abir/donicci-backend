require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  teardown do
    Product.delete_all
    Category.delete_all
  end  

  test "index: paginated results" do
    x = 1
    while(x <= 10)
      product_instance("product: " + x.to_s).save

      x = x + 1
    end

    get "/products"

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal "product: 10", response.first["title"]
    assert_equal "product: 6", response.last["title"]
  end

  test "index: paginated results next page" do
    x = 1
    nextPage = ""
    while(x <= 10)
      product = product_instance("product: " + x.to_s)
      product.save
      product.updated_at = Time.new(product.updated_at.to_s) + (60 * x)
      product.save

      if x == 6
        nextPage = product.updated_at
      end

      x = x + 1
    end

    get "/products?next=" + nextPage.to_s

    
    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 5, response.length
    assert_equal "product: 5", response[0]["title"]
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

  test "show: finds one" do
    product = product_instance
    product.save
    
    get "/products/" + product._id

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal product[:title], response["title"]
  end

  test "show: finds one with categories" do
    category1 = category_instance("category 1")
    assert category1.save
    category2 = category_instance("category 2")
    assert category2.save
    product = product_instance
    product.categories.push(category1)
    product.categories.push(category2)
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

  test "create: saves product" do
    post "/products/", params: {product: {title: "Product", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 1}}

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert response["_id"]

    productsSaved = Product.all
    assert_equal 1, productsSaved.length
  end

  test "create: returns error without product" do
    post "/products/", params: {}

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'product' in request body", response["msg"]
  end

  test "create: doesn't save product with empty title" do
    post "/products/", params: {product: {title: nil, images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 1}}

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Title must be provided"
    assert_equal 400, @response.status

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save product with no images" do
    post "/products/", params: {product: {title: "Product", images: [], price: 300, quantity: 1}}

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Images length should be between 1 and 3"
    assert_equal 400, @response.status

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save product with more than 3 images" do
    post "/products/", params: {product: {title: "Product", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}, {fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 1}}

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Images length should be between 1 and 3"
    assert_equal 400, @response.status

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save when price is not integer" do
    post "/products/", params: {product: {title: "Product", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300.00, quantity: 1}}

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Price must be an integer"
    assert_equal 400, @response.status

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save when price is less than 300" do
    post "/products/", params: {product: {title: "Product", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 299, quantity: 1}}

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Price must be greater than or equal to 300"
    assert_equal 400, @response.status

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save when quantity is not integer" do
    post "/products/", params: {product: {title: "Product", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 1.00}}

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Quantity must be an integer"
    assert_equal 400, @response.status

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "create: doesn't save when quantity is less than 1" do
    post "/products/", params: {product: {title: "Product", images: [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}], price: 300, quantity: 0}}

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Quantity must be greater than or equal to 1"
    assert_equal 400, @response.status

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "destroy: deletes product" do
    product = product_instance
    product.save

    delete "/products/" + product._id

    assert_equal 201, @response.status

    productsSaved = Product.all
    assert_equal 0, productsSaved.length
  end

  test "destroy: 404 when not found" do
    delete "/products/" + "123"

    response = JSON.parse(@response.body)
    assert_equal response["msg"], "Product not found"
    assert_equal 404, @response.status
  end

  test "update: updates product" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}], price: 350, quantity: 2}}

    put "/products/" + product._id, params: updatedProduct 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal updatedProduct[:product][:title], response["title"]
    assert_equal updatedProduct[:product][:images].length, response["images"].length
    assert_equal updatedProduct[:product][:price], response["price"]
    assert_equal updatedProduct[:product][:quantity], response["quantity"]
  end

  test "update: updates product without title" do
    product = product_instance
    product.save

    updatedProduct = {product: {images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}], price: 350, quantity: 2}}

    put "/products/" + product._id, params: updatedProduct 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal product.title, response["title"]
    assert_equal updatedProduct[:product][:images].length, response["images"].length
    assert_equal updatedProduct[:product][:price], response["price"]
    assert_equal updatedProduct[:product][:quantity], response["quantity"]
  end

  test "update: updates product without images" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", price: 350, quantity: 2}}

    put "/products/" + product._id, params: updatedProduct 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal updatedProduct[:product][:title], response["title"]
    assert_equal product.images.length, response["images"].length
    assert_equal updatedProduct[:product][:price], response["price"]
    assert_equal updatedProduct[:product][:quantity], response["quantity"]
  end

  test "update: updates product without price" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}], quantity: 2}}

    put "/products/" + product._id, params: updatedProduct 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal updatedProduct[:product][:title], response["title"]
    assert_equal updatedProduct[:product][:images].length, response["images"].length
    assert_equal product.price, response["price"]
    assert_equal updatedProduct[:product][:quantity], response["quantity"]
  end

  test "update: updates product without quantity" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}], price: 350}}

    put "/products/" + product._id, params: updatedProduct 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal updatedProduct[:product][:title], response["title"]
    assert_equal updatedProduct[:product][:images].length, response["images"].length
    assert_equal updatedProduct[:product][:price], response["price"]
    assert_equal product.quantity, response["quantity"]
  end

  test "update: returns error without product in request body" do
    product = product_instance
    product.save

    updatedProduct = {}

    put "/products/" + product._id, params: updatedProduct 

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'product' in request body", response["msg"]
  end

  test "update: doesn't update product with more than 3 images" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}, {fileId: "5", url: "https://hasanabir.netlify.app/"}, {fileId: "6", url: "https://hasanabir.netlify.app/"}], price: 350, quantity: 2}}

    put "/products/" + product._id, params: updatedProduct

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Images length should be between 1 and 3"
    assert_equal 400, @response.status
  end

  test "update: doesn't update when price is not integer" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}], price: 350.00, quantity: 2}}

    put "/products/" + product._id, params: updatedProduct

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Price must be an integer"
    assert_equal 400, @response.status
  end

  test "update: doesn't update when price is less than 300" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}], price: -350, quantity: 2}}

    put "/products/" + product._id, params: updatedProduct

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Price must be greater than or equal to 300"
    assert_equal 400, @response.status
  end

  test "update: doesn't update when quantity is not integer" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}], price: 350, quantity: 2.00}}

    put "/products/" + product._id, params: updatedProduct

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Quantity must be an integer"
    assert_equal 400, @response.status
  end

  test "update: doesn't update when quantity is less than 1" do
    product = product_instance
    product.save

    updatedProduct = {product: {title: "Updated product", images: [{fileId: "3", url: "https://hasanabir.netlify.app/"}, {fileId: "4", url: "https://hasanabir.netlify.app/"}], price: 350, quantity: -2}}

    put "/products/" + product._id, params: updatedProduct

    response = JSON.parse(@response.body)
    assert response["msgs"].include? "Quantity must be greater than or equal to 1"
    assert_equal 400, @response.status
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

    updatedProduct = {category_ids: category_ids}

    put "/products/" + product._id + "/categories", params: updatedProduct 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 2, response["category_list"].length
    assert_equal category1.name, response["category_list"][0]["name"]
    assert_equal category2.name, response["category_list"][1]["name"]
  end

  test "add_categories: returns error without category_ids" do
    product = product_instance
    product.save

    put "/products/" + product._id + "/categories", params: {}

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'category_ids' in request body", response["msg"]
  end

  test "remove_categories: adds categories to product" do
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

    updatedProduct = {category_ids: category_ids}

    put "/products/" + product._id + "/categories/remove", params: updatedProduct 

    response = JSON.parse(@response.body)
    assert_equal 200, @response.status
    assert_equal 1, response["category_list"].length
    assert_equal category1.name, response["category_list"][0]["name"]
  end

  test "remove_categories: returns error without category_ids" do
    product = product_instance
    product.save

    put "/products/" + product._id + "/categories/remove", params: {}

    response = JSON.parse(@response.body)
    assert_equal 400, @response.status
    assert_equal "Requires 'category_ids' in request body", response["msg"]
  end

  def product_instance(product_title = "test product") 
    product = Product.new
    product.title = product_title
    product.images = [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}]
    product.price = 300
    product.quantity = 1

    return product
  end
  def category_instance(category_name = "test category") 
    category = Category.new
    category.name = category_name

    return category
  end
end