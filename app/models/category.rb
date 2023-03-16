class Category
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String

  validates :name, presence: { message: "must be provided" }
end
