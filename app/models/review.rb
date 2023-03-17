class Review
  include Mongoid::Document
  include Mongoid::Timestamps
  field :description, type: String
  belongs_to :product
  belongs_to :user

  validates :description, presence: { message: "must be provided" }
end
