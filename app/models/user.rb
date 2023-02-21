class User
  include Mongoid::Document
  include Mongoid::Timestamps
  field :username, type: String
  field :email, type: String
  field :password_hash, type: String
  field :password_salt, type: String
  has_and_belongs_to_many :roles
  has_many :cart_items
  has_many :reviews
  has_many :ratings

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: {with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i}
  validates :password_hash, presence: true
  validates :password_salt, presence: true
end
