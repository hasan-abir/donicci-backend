require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    DatabaseCleaner[:mongoid].start
  end
    
  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "review: should save" do
    review = review_instance
    product = product_instance
    product.save
    user = user_instance
    role = role_instance
    user.role_ids.push(role._id)
    user.save
    review.user_id = user._id
    review.product_id = product._id
    assert review.save
  end

  test "review: should not save when description isn't provided" do
    review = review_instance
    review.description = nil

    assert_not review.save
    assert review.errors.full_messages.include? "Description must be provided"
  end
end
