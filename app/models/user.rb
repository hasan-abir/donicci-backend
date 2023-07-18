class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::SecurePassword

  field :display_name, type: String
  field :username, type: String
  field :email, type: String
  field :password_digest, type: String
  has_and_belongs_to_many :roles, inverse_of: nil

  has_secure_password

  validates :username, :display_name, :email, presence: {message: "must be provided"}
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "address is invalid" }
  validates :password, length: {minimum: 8, message: "length should be 8 characters minimum"}, allow_blank: true
  validates :role_ids, length: {minimum: 1, message: "length should be 1 minimum"}

  validates_format_of :username, with: /\A(?=.*[a-z])(?=.*\d)(?=.*_)[a-z0-9_]+\z/i, message: "must contain lowercase letters, numbers, and underscores"
  validates_uniqueness_of :username, :email, message: "must be unique"
  index({ username: 1, email: 1 }, { unique: true })
end
