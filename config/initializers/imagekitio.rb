ImageKitIo.configure do |config|
    config.public_key = ENV["IMAGEKIT_PUBLIC_KEY"]
    config.private_key = ENV["IMAGEKIT_PRIVATE_KEY"]
    config.url_endpoint = ENV["IMAGEKIT_URL_ENDPOINT"]
end
