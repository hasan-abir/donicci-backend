class Rating
  include Mongoid::Document
  include Mongoid::Timestamps
  field :score, type: Integer
  belongs_to :product
  belongs_to :user

  validates :score, presence: { message: "must be provided" }, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
end
