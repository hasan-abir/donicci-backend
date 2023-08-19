class CartItem
  include Mongoid::Document
  include Mongoid::Timestamps
  field :selected_quantity, type: Integer
  belongs_to :product
  belongs_to :user

  validates :selected_quantity, presence: { message: "must be provided" }, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  validates_uniqueness_of :product_id, scope: :user_id, message: "is already in the cart for this user"
end
