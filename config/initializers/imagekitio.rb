ImageKitIo.configure do |config|
  if Rails.env.development? || Rails.env.test?
    config.public_key = ENV["IMAGEKIT_PUBLIC_KEY"]
    config.private_key = ENV["IMAGEKIT_PRIVATE_KEY"]
    config.url_endpoint = ENV["IMAGEKIT_URL_ENDPOINT"]
  end
end