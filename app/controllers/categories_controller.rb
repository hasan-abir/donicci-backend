require "jwt_authentication"

class CategoriesController < ApplicationController
    include JwtAuthentication

    before_action :authenticate_user, only: [:create, :destroy, :update] do
        check_for_roles(["ROLE_ADMIN"])
    end
    prepend_before_action :set_category, only: [:show, :destroy, :update]

    def_param_group :category do
        property :_id, String
        property :name, String
    end

    def_param_group :category_in_list do
        param_group :category
        property :updated_at, String
    end
    
    api!
    param :limit, Integer
    param :next, String
    returns :array_of => :category_in_list, :code => 200
    def index 
        limit = params[:limit] ? params[:limit] : 5
        nextPage = params[:next] ? Time.new(params[:next]) : Time.now.utc

        categories = Category.where(:updated_at.lt => nextPage).limit(limit).only(:_id, :name, :updated_at).order_by(updated_at: "desc")

        render json: categories
    end

    api!
    returns :category, :code => 200
    def show 
        render json: get_category_details_json(@category)
    end

    api!
    param :category, Hash, :required => true do
        param :name, String, :required => true
    end
    header 'Authorization', 'Bearer {admin access token}', :required => true
    returns :category, :code => 200
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
            render json: get_category_details_json(category)
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
    returns :category, :code => 200
    def update 
        unless params[:category]
            return render json: {msg: "Requires 'category' in request body"}.to_json, status: 400
        end
        
        @category.name = params[:category][:name].presence || @category.name
        
        @category.save
        
        if @category.errors.full_messages.length > 0
            render json: {msgs: @category.errors.full_messages}.to_json, status: 400
        else
            render json: get_category_details_json(@category)
        end
    end

    def get_category_details_json(category)
        category.to_json(only: [:_id, :name])
    end

    def set_category
        category_instance = Category.find(params[:id])

        if category_instance == nil
            render json: {msg: "Category not found"}.to_json, status: 404
        end

        @category = category_instance
    end
end
