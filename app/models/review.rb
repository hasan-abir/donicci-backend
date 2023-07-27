class Review
  include Mongoid::Document
  include Mongoid::Timestamps
  field :description, type: String
  belongs_to :product
  belongs_to :user

  # attr_accessor :author

  validates :description, presence: { message: "must be provided" }

  # def as_json(options = {})
  #   super(options).merge('author' => author)
  # end
end
