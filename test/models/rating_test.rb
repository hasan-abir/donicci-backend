require "test_helper"

class RatingTest < ActiveSupport::TestCase
  teardown do
    Rating.delete_all
    Product.delete_all
    User.delete_all
  end  

  test "should save" do
    assert rating_instance.save
  end

  test "should not save when score isn't provided" do
    rating = rating_instance
    rating.score = nil

    assert_not rating.save
    assert rating.errors.full_messages.include? "Score must be provided"
  end

  test "should not save when score isn't number" do
    rating = rating_instance
    rating.score = 1.5

    assert_not rating.save
    assert rating.errors.full_messages.include? "Score must be an integer"
  end

  test "should not save when score is less than 1" do
    rating = rating_instance
    rating.score = 0

    assert_not rating.save
    assert rating.errors.full_messages.include? "Score must be greater than or equal to 1"
  end

  test "should not save when score is more than 5" do
    rating = rating_instance
    rating.score = 6

    assert_not rating.save
    assert rating.errors.full_messages.include? "Score must be less than or equal to 5"
  end

  def rating_instance(score = 4) 
    rating = Rating.new
    rating.score = score
    product = product_instance
    product.save
    rating.product = product
    user = user_instance
    user.save
    rating.user = user

    return rating
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
