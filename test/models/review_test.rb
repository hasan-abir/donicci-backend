require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  teardown do
    Review.delete_all
    Product.delete_all
    User.delete_all
    Role.delete_all
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

  def review_instance(description = "Lorem") 
    review = Review.new
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
  def user_instance(username = "test", email = "test@test.com", password = "testtest")
    role = role_instance
    role.save

    user = User.new
    user.username = username
    user.email = email
    user.password = password
    user.roles.push(role)

    return user
  end  
  def role_instance(name = "ROLE_USER")
    role = Role.new
    role.name = name

    return role
  end  
end
