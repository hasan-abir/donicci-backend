require "jwt_authentication"

class UsersController < ApplicationController
  include JwtAuthentication
  before_action :authenticate_user, only: [:show]

  def_param_group :user do
    property :username, String
    property :display_name, String
  end

  def_param_group :tokens do
    property :access_token, String
    property :refresh_token, String
  end

  api!
  header 'Authorization', 'Bearer {token}', :required => true
  returns :user, :code => 200
  def show
    current_user = request.env[:current_user]
    render json: current_user.to_json(only: [:username, :display_name])
  end

  api!
  param :user, Hash, :required => true do
    param :display_name, String, :required => true
    param :username, String, :required => true
    param :email, String, :required => true
    param :password, String, :required => true
  end
  returns :tokens, :code => 200
  def create
    emptyReqBodyMsg = "Requires 'user' in request body with fields:"

    for i in User.attribute_names.concat(["roles", "password"]) do
        unless ['_id', 'created_at', 'updated_at', 'password_digest', "role_ids"].include? i
                emptyReqBodyMsg.concat(" " + i)       
        end
    end

    unless params[:user]
        return render json: {msg: emptyReqBodyMsg}.to_json, status: 400
    end

    user = User.new
    user.display_name = params[:user][:display_name]
    user.username = params[:user][:username]
    user.email = params[:user][:email]
    user.password = params[:user][:password]

    role = Role.find_or_create_by(name: "ROLE_USER")

    user.roles.push(role)

    user.save
    
    if user.errors.full_messages.length > 0
        render json: {msgs: user.errors.full_messages}.to_json, status: 400
    else
        access_token = JWT.encode({ user_id: user._id, exp: token_expiration_times()[:access] }, Rails.application.secret_key_base)

        refresh_token_obj = refresh_token_instance(user._id)
        refresh_token_obj.save

        render json: { access_token: access_token, refresh_token: refresh_token_obj.token }
    end
  end

  def refresh_token_instance(user_id) 
    refresh_token = RefreshToken.find_or_create_by(user_id: user_id)
    refresh_token.token = JWT.encode({ user_id: user_id, exp: token_expiration_times()[:refresh] }, Rails.application.secret_key_base)

    refresh_token
  end

  def token_expiration_times
    times = {
      access: Time.now.to_i + ENV['ACCESS_EXPIRATION_SECONDS'].to_i,
      refresh: Time.now.to_i + ENV['REFRESH_EXPIRATION_HOURS'].to_i * 3600      
    }
  end
end
