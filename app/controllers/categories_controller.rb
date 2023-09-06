require "jwt_authentication"

class CategoriesController < ApplicationController
    include JwtAuthentication

    before_action :authenticate_user, only: [:create, :destroy, :update] do
        check_for_roles(["ROLE_ADMIN"])
    end
    prepend_before_action :set_category, only: [:show, :destroy, :update]
    
    api!
    param :limit, Integer
    param :next, String
    def index 
        limit = params[:limit] ? params[:limit] : 5
        nextPage = params[:next] ? Time.new(params[:next]) : Time.now.utc

        categories = Category.where(:updated_at.lt => nextPage).limit(limit).order_by(updated_at: "desc")
        render json: categories
    end

    api!
    def show 
        render json: @category
    end

    api!
    param :category, Hash, :required => true do
        param :name, String, :required => true
    end
    header 'Authorization', 'Bearer {admin access token}', :required => true
    def create
        unless params[:category]
            return render json: {msg: "Requires 'category' in request body"}.to_json, status: 400
        end

        category = Category.new()
        category.name = params[:category][:name]

        category.save
        
        if category.errors.full_messages.length > 0
            render json: {msgs: category.errors.full_messages}.to_json, status: 400
        else
            render json: category
        end
    end

    api!
    header 'Authorization', 'Bearer {admin access token}', :required => true
    def destroy 
        @category.destroy

        render status: 201
    end

    api!
    param :category, Hash, :required => true do
        param :name, String
    end
    header 'Authorization', 'Bearer {admin access token}', :required => true
    def update 
        unless params[:category]
            return render json: {msg: "Requires 'category' in request body"}.to_json, status: 400
        end
        
        @category.name = params[:category][:name].presence || @category.name
        
        @category.save
        
        if @category.errors.full_messages.length > 0
            render json: {msgs: @category.errors.full_messages}.to_json, status: 400
        else
            render json: @category
        end
    end

    def set_category
        category_instance = Category.find(params[:id])

        if category_instance == nil
            render json: {msg: "Category not found"}.to_json, status: 404
        end

        @category = category_instance
    end
end
