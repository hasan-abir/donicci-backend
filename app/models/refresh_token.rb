class RefreshToken
  include Mongoid::Document
  include Mongoid::Timestamps
  field :token, type: String
  belongs_to :user

  validates :token, presence: { message: "must be provided" }
end
