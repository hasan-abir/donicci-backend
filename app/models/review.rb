class Review
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :description, type: String
  belongs_to :product
  belongs_to :user

  validates :title, presence: true
  validates :description, presence: true
end
