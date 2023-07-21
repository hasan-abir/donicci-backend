require "test_helper"

class RatingTest < ActiveSupport::TestCase
  setup do
    DatabaseCleaner[:mongoid].start
  end
    
  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "rating: should save" do
    rating = rating_instance
    product = product_instance
    product.save
    user = user_instance
    role = role_instance
    user.role_ids.push(role._id)
    user.save

    rating.user_id = user._id
    rating.product_id = product._id

    assert rating.save
  end

  test "rating: should not save when score isn't provided" do
    rating = rating_instance
    rating.score = nil

    assert_not rating.save
    assert rating.errors.full_messages.include? "Score must be provided"
  end

  test "rating: should not save when score isn't number" do
    rating = rating_instance
    rating.score = 1.5

    assert_not rating.save
    assert rating.errors.full_messages.include? "Score must be an integer"
  end

  test "rating: should not save when score is less than 1" do
    rating = rating_instance
    rating.score = 0

    assert_not rating.save
    assert rating.errors.full_messages.include? "Score must be greater than or equal to 1"
  end

  test "rating: should not save when score is more than 5" do
    rating = rating_instance
    rating.score = 6

    assert_not rating.save
    assert rating.errors.full_messages.include? "Score must be less than or equal to 5"
  end
end
