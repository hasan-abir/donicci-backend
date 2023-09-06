require "jwt_authentication"

class RolesController < ApplicationController
    include JwtAuthentication

    before_action :authenticate_user do
        check_for_roles(["ROLE_ADMIN"])
    end
    prepend_before_action :set_role

    api!
    param :username, String, :required => true
    header 'Authorization', 'Bearer {admin access token}', :required => true
    def assign_role
        user = User.where(username: params[:username]).first

        if user == nil
            return render json: {msg: "User not found"}.to_json, status: 404
        end

        user.role_ids.push(@role._id)
        
        user.save

        render json: {msg: "'" + user.username + "' has been assigned role: '" + @role.name + "'"}
    end

    def set_role
        role_instance = Role.find(params[:id])
    
        if role_instance == nil
            render json: {msg: "Role not found"}.to_json, status: 404
        end

        @role = role_instance
    end
end
