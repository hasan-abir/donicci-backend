require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  teardown do
    Review.delete_all
    Product.delete_all
    User.delete_all
  end  

  test "should save" do
    assert review_instance.save
  end

  test "should not save when title isn't provided" do
    review = review_instance
    review.title = nil

    assert_not review.save
    assert review.errors.full_messages.include? "Title must be provided"
  end

  test "should not save when description isn't provided" do
    review = review_instance
    review.description = nil

    assert_not review.save
    assert review.errors.full_messages.include? "Description must be provided"
  end

  def review_instance(title = "Great", description = "Lorem") 
    review = Review.new
    review.title = title
    review.description = description
    product = product_instance
    product.save
    review.product = product
    user = user_instance
    user.save
    review.user = user

    return review
  end
  def product_instance(product_title = "test product") 
    product = Product.new
    product.title = product_title
    product.images = [{fileId: "1", url: "https://hasanabir.netlify.app/"}, {fileId: "2", url: "https://hasanabir.netlify.app/"}]
    product.price = 300
    product.quantity = 1

    return product
  end
  def user_instance(username = "Test", email = "test@test.com")
    user = User.new
    user.username = username
    user.email = email
    user.password_hash = "bcrypthash"
    user.password_salt = "bcryptsalt"

    return user
  end
end
