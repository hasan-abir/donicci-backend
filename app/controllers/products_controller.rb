require "jwt_authentication"
require "imagekit_helper"

class ProductsController < ApplicationController
    include JwtAuthentication
    include ImagekitHelper

    before_action :authenticate_user, only: [:create, :destroy, :update, :add_categories, :remove_categories] do
        check_for_roles(["ROLE_ADMIN"])
    end
    append_before_action :set_product, only: [:show, :destroy, :update, :add_categories, :remove_categories]

    def_param_group :product do
        property :_id, String
        property :images, :array_of => Hash
        property :price, Integer
        property :title, String
        property :user_rating, Integer
    end

    def_param_group :product_in_list do
        param_group :product
        property :updated_at, String
    end

    api!
    param :limit, Integer
    param :next, String
    param :search_term, String
    param :category_id, String
    returns :array_of => :product_in_list, :code => 200
    def index
        limit = params[:limit] || 5
        next_page = params[:next] ? Time.new(params[:next]) : Time.now.utc
        search_term = params[:search_term]
        category_id = params[:category_id]

        where_arguments = {}

        where_arguments[:updated_at.lt] = next_page
        where_arguments[:category_ids] = category_id if category_id

        if search_term
            products = Product.text_search(search_term).where(where_arguments).limit(limit).only(:_id, :title, :price, :images, :user_rating, :updated_at).order_by(updated_at: "desc")
        else
            products = Product.where(where_arguments).limit(limit).only(:_id, :title, :price, :images, :user_rating, :updated_at).order_by(updated_at: "desc")
        end

        render json: products
    end

    api!
    returns :product, :code => 200
    def show
        render json: get_product_details_json(@product)
    end

    api!
    param :product, Hash, :required => true do
        param :title, String, :required => true
        param :description, String
        param :image_files, Array, of: File, :required => true
        param :price, Integer, :required => true
        param :quantity, Integer, :required => true
    end
    header 'Authorization', 'Bearer {admin access token}', :required => true
    returns :product, :code => 200
    def create
        emptyReqBodyMsg = "Requires 'product' in request body with fields:"

        fields_required = Product.attribute_names
        fields_required.push("image_files")

        for i in fields_required do
            unless ['_id', 'created_at', 'updated_at', 'category_ids', 'images', 'user_rating'].include? i
                if i == "description"
                    emptyReqBodyMsg.concat(" " + i + "(optional)")       
                else
                    emptyReqBodyMsg.concat(" " + i)       
                end
            end
        end

        unless params[:product]
            return render json: {msg: emptyReqBodyMsg}.to_json, status: 400
        end

        product = Product.new
        product.title = params[:product][:title]
        product.description = params[:product][:description] || ""
        
        product.image_files = params[:product][:image_files]
        product.price = params[:product][:price]
        product.quantity = params[:product][:quantity]

        if product.valid?
            upload_errors = product.upload_images_save_details

            if upload_errors.length > 0
                return render json: {msgs: upload_errors}.to_json, status: 400
            end

            product.save

            render json: get_product_details_json(product)
        else
            render json: {msgs: product.errors.full_messages}.to_json, status: 400
        end
    end

    api!
    header 'Authorization', 'Bearer {admin access token}', :required => true
    def destroy
        imagekitio = ImageKitIo.client

        image_ids = @product.images.map do |image|
            image["fileId"]
        end

        imagekitio.delete_bulk_files(file_ids: image_ids)

        @product.destroy

        render status: 201
    end

    api!
    param :product, Hash, :required => true do
        param :title, String
        param :description, String
        param :image_files, Array, of: File
        param :price, Integer
        param :quantity, Integer
    end
    header 'Authorization', 'Bearer {admin access token}', :required => true
    returns :product, :code => 200
    def update  
        emptyReqBodyMsg = "Requires 'product' in request body with fields:"

        fields_required = Product.attribute_names
        fields_required.push("image_files")

        for i in fields_required do
            unless ['_id', 'created_at', 'updated_at', 'category_ids', 'images'].include? i
                emptyReqBodyMsg.concat(" " + i + "(optional)")       
            end
        end
        
        unless params[:product]
            return render json: {msg: emptyReqBodyMsg}.to_json, status: 400
        end
        
        @product.title = params[:product][:title].presence || @product.title
        @product.description = params[:product][:description].presence || @product.description
        
        @product.image_files = params[:product][:image_files]

        @product.price = params[:product][:price].presence || @product.price
        @product.quantity = params[:product][:quantity].presence || @product.quantity
        @product.save

        if @product.valid?
            upload_errors = @product.upload_images_save_details

            if upload_errors.length > 0
                return render json: {msgs: upload_errors}.to_json, status: 400
            end

            @product.save

            render json: get_product_details_json(@product)
        else
            render json: {msgs: @product.errors.full_messages}.to_json, status: 400
        end
    end

    api!
    param :category_ids, Array, of: String
    header 'Authorization', 'Bearer {admin access token}', :required => true
    returns :product, :code => 200
    def add_categories
        if !params[:category_ids] || params[:category_ids].class != Array
            return render json: {msg: "Requires 'category_ids' array in request body"}.to_json, status: 400
        end

        for i in params[:category_ids] do
            category = Category.find(i)

            if category
                @product.categories.push(category)
            end
        end

        @product.save

        render json: get_product_details_json(@product)
    end

    api!
    param :category_ids, Array, of: String
    header 'Authorization', 'Bearer {admin access token}', :required => true
    returns :product, :code => 200
    def remove_categories
        if !params[:category_ids] || params[:category_ids].class != Array
            return render json: {msg: "Requires 'category_ids' array in request body"}.to_json, status: 400
        end

        for i in params[:category_ids] do
            category = Category.find(i)

            if category
                @product.categories.delete(category)
            end
        end

        @product.save

        render json: get_product_details_json(@product)
    end

    def get_product_details_json(product)
        product[:category_list] = product.categories.only(:_id, :name)

        product.to_json(only: [:_id, :title, :price, :quantity, :description, :user_rating, :images, :category_list, :updated_at.lt])
    end

    def set_product
        product_instance = Product.find(params[:id])
    
        if product_instance == nil
            render json: {msg: "Product not found"}.to_json, status: 404
        end

        @product = product_instance
    end
end