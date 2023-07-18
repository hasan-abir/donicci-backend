class UsersController < ApplicationController
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
        render json: user.as_json(except: [:_id, :created_at, :updated_at, :password_digest])
    end
  end
end
