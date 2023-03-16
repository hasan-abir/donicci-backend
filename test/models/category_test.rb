require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  teardown do
    Product.delete_all
    Category.delete_all
  end  

  test "does save" do
    assert category_instance.save
  end

  test "does not save when name is nil" do
    category = category_instance
    category.name = nil

    assert_not category.save
    assert category.errors.full_messages.include? "Name must be provided"
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
