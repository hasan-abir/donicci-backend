require "test_helper"

class RefreshTokenTest < ActiveSupport::TestCase
  setup do
    DatabaseCleaner[:mongoid].start
  end
    
  teardown do
    DatabaseCleaner[:mongoid].clean
  end

  test "refresh_token: should save" do
    refresh_token = refresh_token_instance

    assert refresh_token.save
  end

  test "refresh_token: should not save without token" do
    refresh_token = refresh_token_instance
    refresh_token.token = nil

    assert_not refresh_token.save
  end
end
