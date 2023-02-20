class Role
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  has_and_belongs_to_many :users

  validates :name, presence: true, uniqueness: true, inclusion: {in: %w(ROLE_USER ROLE_ADMIN)}
end
