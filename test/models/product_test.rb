require "test_helper"

class ProductTest < ActiveSupport::TestCase
  teardown do
    Product.delete_all
    Category.delete_all
  end  

  test "does save" do
    assert product_instance.save
  end

  test "does save with categories" do
    category1 = category_instance("category 1")
    assert category1.save
    category2 = category_instance("category 2")
    assert category2.save
    product = product_instance
    product.categories.push(category1)
    product.categories.push(category2)

    assert product.save
    assert_equal(2, product.categories.length)
  end

  test "does save not with categories more than 5" do
    product = product_instance

    x = 1

    while x <= 6
      category = category_instance("category " + x.to_s)
      category.save

      product.categories.push(category)
      x = x + 1
    end

    assert_not product.save
    assert product.errors.full_messages.include? "Categories length should be 5 and less"
  end

  test "does not save when title is nil" do
    product = product_instance
    product.title = nil

    assert_not product.save
    assert product.errors.full_messages.include? "Title must be provided"
  end

  test "does not save when there are no images" do
    product = product_instance
    product.images = []

    assert_not product.save
    assert product.errors.full_messages.include? "Images length should be between 1 and 3"
  end

  test "does not save when there are more than 3 images" do
    product = product_instance
    product.images.push({fileId: "3", url: "https://hasanabir.netlify.app/"})
    product.images.push({fileId: "4", url: "https://hasanabir.netlify.app/"})

    assert_not product.save
    assert product.errors.full_messages.include? "Images length should be between 1 and 3"
  end

  test "does not save when price is not integer" do
    product = product_instance
    product.price = 300.00

    assert_not product.save
    assert product.errors.full_messages.include? "Price must be an integer"
  end

  test "does not save when price is less than 300" do
    product = product_instance
    product.price = 299

    assert_not product.save
    assert product.errors.full_messages.include? "Price must be greater than or equal to 300"
  end

  test "does not save when quantity is not integer" do
    product = product_instance
    product.quantity = 1.00

    assert_not product.save
    assert product.errors.full_messages.include? "Quantity must be an integer"
  end

  test "does not save when quantity is less than 1" do
    product = product_instance
    product.quantity = 0

    assert_not product.save
    assert product.errors.full_messages.include? "Quantity must be greater than or equal to 1"
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
