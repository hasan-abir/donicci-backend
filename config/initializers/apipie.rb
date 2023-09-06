Apipie.configure do |config|
  config.app_name                = "Donicci Backend"
  config.api_base_url            = ""
  config.doc_base_url            = "/apidocs"
  config.app_info = "Source code: https://github.com/hasan-abir/donicci-backend"
  config.validate = false
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/**/*.rb"
end
