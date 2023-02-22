class Role
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  has_and_belongs_to_many :users

  validates :name, presence: { message: "must be provided" }, uniqueness: { message: "'%{value}' already exists" }, inclusion: {in: %w(ROLE_USER ROLE_ADMIN), message: "must include: ROLE_USER | ROLE_ADMIN" }
end
