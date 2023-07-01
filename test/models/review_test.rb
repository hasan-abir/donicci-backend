require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    DatabaseCleaner[:mongoid].start
  end
    
  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "review: should save" do
    assert review_instance.save
  end

  test "review: should not save when description isn't provided" do
    review = review_instance
    review.description = nil

    assert_not review.save
    assert review.errors.full_messages.include? "Description must be provided"
  end
end
