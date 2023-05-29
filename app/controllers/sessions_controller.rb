class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      token = JWT.encode({ user_id: user._id }, Rails.application.secret_key_base)
      render json: { token: token }
    else
      render json: { msg: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def destroy
    # TODO: Implement logout logic
  end
end
