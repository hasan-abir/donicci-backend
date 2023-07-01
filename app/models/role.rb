class Role
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String

  validates :name, presence: { message: "must be provided" }, uniqueness: { message: "'%{value}' already exists" }, inclusion: {in: %w(ROLE_USER ROLE_ADMIN ROLE_MODERATOR), message: "must include: ROLE_USER | ROLE_ADMIN | ROLE_MODERATOR" }

  index({ name: 1 }, { unique: true })
end
