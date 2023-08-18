require "test_helper"

class ProductTest < ActiveSupport::TestCase
  setup do
    DatabaseCleaner[:mongoid].start
  end
    
  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "product: does save" do
    assert product_instance.save
  end

  test "product: does not save (presence validation)" do
    product = Product.new

    assert_not product.save

    assert product.errors.full_messages.include? "Title must be provided"
    assert product.errors.full_messages.include? "Image files must be provided as an array"
    assert product.errors.full_messages.include? "Price must be provided"
    assert product.errors.full_messages.include? "Quantity must be provided"
    assert product.errors.full_messages.include? "User rating must be provided"

    assert_equal 0, Product.all.length
  end

  test "product: does not save (integer validation)" do
    product = product_instance
    product.price = "four hundred"
    product.quantity = "ten"
    product.user_rating = "four point five"

    assert_not product.save

    assert product.errors.full_messages.include? "Price is not a number"
    assert product.errors.full_messages.include? "Quantity is not a number"
    assert product.errors.full_messages.include? "User rating is not a number"

    assert_equal 0, Product.all.length
  end

  test "product: does not save (length validation)" do
    product = product_instance
    product.price = 200
    product.quantity = 0
    product.user_rating = -1

    assert_not product.save

    assert product.errors.full_messages.include? "Price must be greater than or equal to 300"
    assert product.errors.full_messages.include? "Quantity must be greater than or equal to 1"
    assert product.errors.full_messages.include? "User rating must be greater than or equal to 0"

    product.user_rating = 6

    x = 1
    while x <= 6
      category = Category.new
      category.name = "Category " + x.to_s

      product.categories.push(category)

      x = x + 1
    end

    assert_not product.save

    assert product.errors.full_messages.include? "User rating must be less than or equal to 5"
    assert product.errors.full_messages.include? "Categories length should be 5 and less"

    assert_equal 0, Product.all.length
  end

  
  test "product: does not save (image files validation)" do
    product = product_instance
    product.image_files = []

    assert_not product.save

    assert product.errors.full_messages.include? "Image files length should be between 1 and 3"

    product.image_files = ["file 1", "file 2", "file 3", "file 4"]

    assert_not product.save

    assert product.errors.full_messages.include? "Image files length should be between 1 and 3"

    product.image_files = ["file 1", "file 2", "file 3"]

    assert_not product.save

    assert product.errors.full_messages.include? "File must be a valid file attachment"

    product.image_files = [upload_image("jelliecat.txt", "text/plain")]

    assert_not product.save

    assert product.errors.full_messages.include? "File must be of image type"

    product.image_files = [upload_image("windowcat.jpg")]

    assert_not product.save

    assert product.errors.full_messages.include? "File size must be less than or equal to 2 mb"

    assert_equal 0, Product.all.length
  end
end
