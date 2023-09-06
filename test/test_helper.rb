ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Mongoid.load!('./config/mongoid.yml', :test)

class ActiveSupport::TestCase
  parallelize_setup do |worker|
    # setup databases
    updated_database = "donicci_test"
    
    updated_database += "_#{worker}" if worker > 0

    Mongoid::Config.clients[:default][:database] = updated_database
  end

  parallelize_teardown do |worker|
    # drop databases
    Mongoid::Clients.default.database.drop
  end

  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Add more helper methods to be used by all tests here...

def generate_token (type = "user")
  user = User.where(username: "hasan_abir1999").first
  user.role_ids.clear

  case type
      when "admin"
          role_admin = Role.where(name: "ROLE_ADMIN").first
          user.role_ids.push(role_admin._id)

      else
          role_user = Role.where(name: "ROLE_USER").first
          user.role_ids.push(role_user._id)
  end

  user.save

  JWT.encode({ user_id: user._id, exp: Time.now.to_i + ENV['ACCESS_EXPIRATION_SECONDS'].to_i.seconds }, Rails.application.secret_key_base)
end

  def cart_item_instance(quantity = 10) 
    cartItem = CartItem.new
    cartItem.selected_quantity = quantity

    cartItem
  end
  def product_instance(product_title = "test product") 
    product = Product.new
    product.title = product_title
    product.image_files = [upload_image("pianocat.jpeg"), upload_image("jelliecat.jpg")]
    product.price = 300
    product.quantity = 1
    product.user_rating = 0

    product
  end
  def category_instance(category_name = "test category") 
    category = Category.new
    category.name = category_name

    category
  end
  def user_instance(username = "hasan_abir1999", email = "test@test.com", password = "testtest", display_name = "Hasan Abir") 
    user = User.new
    user.display_name = display_name
    user.username = username
    user.email = email
    user.password = password

    user
  end
  def role_instance(name = "role_user") 
    role = Role.new
    role.name = name

    role
  end
  def refresh_token_instance() 
    user = user_instance
    role = role_instance
    refresh_token = RefreshToken.new
    refresh_token.token = JWT.encode({ user_id: user._id, exp: Time.now.to_i + ENV['REFRESH_EXPIRATION_HOURS'].to_i * 3600 }, Rails.application.secret_key_base)

    user.role_ids.push(role._id)
    user.save

    refresh_token.user = user

    refresh_token
  end
  def rating_instance(score = 4) 
    rating = Rating.new
    rating.score = score

    rating
  end
  def review_instance(description = "Lorem") 
    review = Review.new
    review.description = description

    review
  end
  def upload_image(path, type = "image/jpeg", upload_request = false)
    unless upload_request
      file_path = Rails.root.join('test', 'fixtures', 'files', path)
      file = File.open(file_path, 'rb')
      
      return ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: File.basename(file_path), type: type)
    end

    fixture_file_upload("#{Rails.root}/test/fixtures/files/" + path, type)
  end
end
