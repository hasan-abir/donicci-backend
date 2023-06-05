class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      access_token = JWT.encode({ user_id: user._id, exp: token_expiration_times()[:access] }, Rails.application.secret_key_base)

      refresh_token_obj = refresh_token_instance(user._id)

      refresh_token_obj.save

      render json: { access_token: access_token, refresh_token: refresh_token_obj.token }
    else
      render json: { msg: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def refresh
    unless params[:token]
      return render json: { msg: 'No token provided' }, status: :unauthorized
    end

    refresh_token = RefreshToken.find_by(token: params[:token])    

    unless refresh_token
      return render json: { msg: 'Token not found' }, status: :unauthorized
    end

    user = User.find(refresh_token.user_id)

    unless user
      return render json: { msg: 'User does not exist anymore' }, status: :unauthorized
    end

    refresh_token.destroy

    new_access_token = JWT.encode({ user_id: user._id, exp: token_expiration_times()[:access] }, Rails.application.secret_key_base)

    new_refresh_token_instance = refresh_token_instance(user._id)
    new_refresh_token_instance.save

    render json: { access_token: new_access_token, refresh_token: new_refresh_token_instance.token }
  end

  def destroy
    unless params[:token]
      return render json: { msg: 'No token provided' }, status: :unauthorized
    end

    refresh_token = RefreshToken.find_by(token: params[:token])    

    unless refresh_token
      return render json: { msg: 'Token not found' }, status: :unauthorized
    end

    refresh_token.destroy

    render status: 201
  end

  def refresh_token_instance(user_id) 
    refresh_token = RefreshToken.new
    refresh_token.token = JWT.encode({ user_id: user_id, exp: token_expiration_times()[:refresh] }, Rails.application.secret_key_base)
    refresh_token.user_id = user_id

    refresh_token
  end

  def token_expiration_times
    times = {
      access: Time.now.to_i + 120,
      refresh: Time.now.to_i + 24 * 3600      
    }
  end
end
