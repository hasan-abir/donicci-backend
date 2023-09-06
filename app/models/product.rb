require "imagekit_helper"

class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  include ImagekitHelper

  field :title, type: String
  field :description, type: String, default: ""
  field :price, type: Integer
  field :quantity, type: Integer
  field :user_rating, type: Float, default: 0
  field :images, type: Array, default: []
  has_and_belongs_to_many :categories, inverse_of: nil
  has_many :cart_items
  has_many :reviews
  has_many :ratings
  index({ title: "text", description: "text" })
  
  attr_accessor :image_files
  validate :image_files_validation

  validates :title, presence: { message: "must be provided" }
  validates :price, presence: { message: "must be provided" }, numericality: {only_integer: true, greater_than_or_equal_to: 300}
  validates :quantity, presence: { message: "must be provided" }, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :user_rating, presence: { message: "must be provided" }, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 5}
  validates :categories, length: {maximum: 5, message: "length should be 5 and less"}

  def image_files_validation
    return if persisted? && !image_files.present?

    if !image_files.instance_of?(Array)
      errors.add(:image_files, "must be provided as an array")
    elsif image_files.length < 1 || image_files.length > 3
      errors.add(:image_files, "length should be between 1 and 3")
    else
      image_files.each do |file|
        allowed_types = ["image/jpeg", "image/png"]
        size_limit = 2

        if !file.instance_of?(ActionDispatch::Http::UploadedFile)
          errors.add(:file, "must be a valid file attachment")
        elsif !allowed_types.include?(file.content_type)
          errors.add(:file, "must be of image type")
        elsif file.size > size_limit.megabytes
          errors.add(:file, "size must be less than or equal to " + size_limit.to_s + " mb")
        end
      end
    end
  end

  def upload_images_save_details
    imagekitio = ImageKitIo.client
    
    return if persisted? && !image_files.present?

    image_ids = images.map do |image| 
          image["fileId"]
    end
      
    imagekitio.delete_bulk_files(file_ids: image_ids) if image_ids.length > 0

    upload_errors = []

    self.images = image_files.map do |file|
          uploaded_image = upload_image_to_cloud(file)

          upload_errors.push(uploaded_image[:error]) if uploaded_image[:error]

          uploaded_image
    end

    upload_errors
  end
end
