class CartItem
  include Mongoid::Document
  include Mongoid::Timestamps
  field :selected_quantity, type: Integer
  belongs_to :product
  belongs_to :user

  validates :selected_quantity, presence: { message: "must be provided" }, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
end
