class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::SecurePassword

  field :username, type: String
  field :email, type: String
  field :password_digest, type: String
  has_and_belongs_to_many :roles, inverse_of: nil

  has_secure_password

  def username=(s)
    write_attribute(:username, s.to_s.titleize)
  end

  validates :username, :email, :password, presence: {message: "must be provided"}
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "address is invalid" }
  validates :password, length: {minimum: 8, message: "length should be 8 characters minimum"}
  validates :roles, length: {minimum: 1, message: "length should be 1 minimum"}

  validates_uniqueness_of :username, :email, message: "must be unique"
end
