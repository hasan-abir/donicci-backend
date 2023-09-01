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
      return render json: { msg: 'No token provided' }, status: 400
    end

    refresh_token = RefreshToken.find_by(token: params[:token])    

    unless refresh_token
      return render json: { msg: 'Token not found' }, status: 404
    end

    begin

      payload = JWT.decode(params[:token], Rails.application.secret_key_base).first

      user = User.find(payload['user_id'])

      unless user
        refresh_token.destroy

        return render json: { msg: 'User does not exist anymore' }, status: 404
      end
    rescue JWT::DecodeError, JWT::VerificationError, JWT::ExpiredSignature
        refresh_token.destroy

        return render json: { msg: 'Unauthorized' }, status: 401
    end

    new_access_token = JWT.encode({ user_id: user._id, exp: token_expiration_times()[:access] }, Rails.application.secret_key_base)

    render json: { access_token: new_access_token, refresh_token: params[:token] }

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
