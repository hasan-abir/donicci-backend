class Role
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String

  validates :name, presence: { message: "must be provided" }, uniqueness: { message: "'%{value}' already exists" }
  validate :name_must_have_role_prefix
  before_validation :uppercase_name, on: :create
  
  def uppercase_name
    self.name = name.upcase if name
  end

  def name_must_have_role_prefix
    prefix = "ROLE_"
    name = self.name

    errors.add(:name, "must start with '#{prefix.downcase}'") if name && !name.start_with?(prefix)
  end

  index({ name: 1 }, { unique: true })
end
