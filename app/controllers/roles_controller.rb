require "jwt_authentication"

class RolesController < ApplicationController
    include JwtAuthentication

    before_action :authenticate_user do
        check_for_roles(["ROLE_ADMIN"])
    end
    prepend_before_action :set_role, only: [:destroy, :assign_role]

    def create
        role = Role.new
        role.name = params[:role]

        role.save

        if role.errors.full_messages.length > 0
            render status: 400, json: {msgs: role.errors.full_messages}
        else
            render json: {msg: "Role added"}
        end
    end

    def destroy
        roles_to_persist = ["ROLE_ADMIN", "ROLE_USER"]

        if roles_to_persist.include? @role.name
            return render status: 400, json: {msg: "Role " + @role.name + " is required for the app"}
        end

        @role.destroy

        render status: 201
    end

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
