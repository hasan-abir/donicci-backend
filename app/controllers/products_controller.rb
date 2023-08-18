require "jwt_authentication"
require "imagekit_helper"

class ProductsController < ApplicationController
    include JwtAuthentication
    include ImagekitHelper

    before_action :authenticate_user, only: [:create, :destroy, :update, :add_categories, :remove_categories] do
        check_for_roles(["ROLE_ADMIN", "ROLE_MODERATOR"])
    end
    append_before_action :set_product, only: [:show, :destroy, :update, :add_categories, :remove_categories]

    def index
        limit = params[:limit] || 5
        next_page = params[:next] ? Time.new(params[:next]) : Time.now.utc
        search_term = params[:search_term]
        category_id = params[:category_id]

        where_arguments = {}

        where_arguments[:updated_at.lt] = next_page
        where_arguments[:category_ids] = category_id if category_id

        if search_term
            products = Product.text_search(search_term).where(where_arguments).limit(limit).only(:_id, :title, :price, :images, :user_rating).order_by(updated_at: "desc")
        else
            products = Product.where(where_arguments).limit(limit).only(:_id, :title, :price, :images, :user_rating).order_by(updated_at: "desc")
        end

        render json: products
    end

    def show
        render json: get_product_details_json(@product)
    end

    def create
        emptyReqBodyMsg = "Requires 'product' in request body with fields:"

        fields_required = Product.attribute_names
        fields_required.push("image_files")

        for i in fields_required do
            unless ['_id', 'created_at', 'updated_at', 'category_ids', 'images'].include? i
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
        product.user_rating = params[:product][:user_rating]

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

    def destroy
        imagekitio = ImageKitIo.client

        image_ids = @product.images.map do |image|
            image["fileId"]
        end

        imagekitio.delete_bulk_files(file_ids: image_ids)

        @product.destroy

        render status: 201
    end

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
        @product.user_rating = params[:product][:user_rating].presence || @product.user_rating
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

        product.to_json(only: [:_id, :title, :price, :quantity, :description, :user_rating, :images, :category_list])
    end

    def set_product
        product_instance = Product.find(params[:id])
    
        if product_instance == nil
            render json: {msg: "Product not found"}.to_json, status: 404
        end

        @product = product_instance
    end
end