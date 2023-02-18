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
    category1.save
    category2 = category_instance("category 2")
    category2.save
    product = product_instance
    product.categories.push(category1)
    product.categories.push(category2)

    assert product.save
    assert_equal(2, product.categories.length)
  end

  test "does not save when title is nil" do
    product = product_instance
    product.title = nil

    assert_not product.save
  end

  test "does not save when there are no images" do
    product = product_instance
    product.images = []

    assert_not product.save
  end

  test "does not save when there are more than 3 images" do
    product = product_instance
    product.images.push({fileId: "3", url: "https://hasanabir.netlify.app/"})
    product.images.push({fileId: "4", url: "https://hasanabir.netlify.app/"})

    assert_not product.save
  end

  test "does not save when price is not integer" do
    product = product_instance
    product.price = 300.00

    assert_not product.save
  end

  test "does not save when price is less than 300" do
    product = product_instance
    product.price = 299

    assert_not product.save
  end

  test "does not save when quantity is not integer" do
    product = product_instance
    product.quantity = 1.00

    assert_not product.save
  end

  test "does not save when quantity is less than 1" do
    product = product_instance
    product.quantity = 0

    assert_not product.save
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
