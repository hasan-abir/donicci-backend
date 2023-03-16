class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :description, type: String, default: ""
  field :price, type: Integer
  field :quantity, type: Integer
  field :images, type: Array, default: []
  has_and_belongs_to_many :categories, inverse_of: nil
  has_many :cart_items
  has_many :reviews
  has_many :ratings

  validates :title, presence: { message: "must be provided" }
  validates :images, length: {minimum: 1, maximum: 3, message: "length should be between 1 and 3"}
  validates :price, numericality: {only_integer: true, greater_than_or_equal_to: 300}
  validates :quantity, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :categories, length: {maximum: 5, message: "length should be 5 and less"}
end
