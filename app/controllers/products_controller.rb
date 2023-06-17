require "jwt_authentication"

class ProductsController < ApplicationController
    include JwtAuthentication

    before_action :authenticate_user, only: [:create, :destroy, :update, :add_categories, :remove_categories] do
        check_for_roles(["ROLE_ADMIN", "ROLE_MODERATOR"])
    end
    prepend_before_action :set_product, only: [:show, :destroy, :update, :add_categories, :remove_categories]

    def index
        limit = params[:limit] ? params[:limit] : 5
        nextPage = params[:next] ? Time.new(params[:next]) : Time.now.utc

        if params[:category_id] && params[:search_term]
            products = Product.text_search(params[:search_term]).where(:updated_at.lt => nextPage, :category_ids => params[:category_id]).limit(limit).only(:_id, :title, :price, :images, :user_rating).order_by(updated_at: "desc")
        elsif params[:search_term] && !params[:category_id]
            products = Product.text_search(params[:search_term]).where(:updated_at.lt => nextPage).limit(limit).only(:_id, :title, :price, :images, :user_rating).order_by(updated_at: "desc")
        elsif params[:category_id] && !params[:search_term]
            products = Product.where(:updated_at.lt => nextPage, :category_ids => params[:category_id]).limit(limit).only(:_id, :title, :price, :images, :user_rating).order_by(updated_at: "desc")
        else
            products = Product.where(:updated_at.lt => nextPage).limit(limit).only(:_id, :title, :price, :images, :user_rating).order_by(updated_at: "desc")
        end

        render json: products
    end

    def show
        render json: get_product_details_json(@product)
    end

    def create
        emptyReqBodyMsg = "Requires 'product' in request body with fields:"

        for i in Product.attribute_names do
            unless ['_id', 'created_at', 'updated_at', 'category_ids'].include? i
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

        product = Product.new()
        product.title = params[:product][:title]
        product.description = params[:product][:description] || ""
        
        images = []

        if params[:product][:images].class == Array
            for i in params[:product][:images] do
                if i.class == ActionController::Parameters
                    image = i.permit([:fileId, :url]).to_h
                    images.push(image)
                end
            end
        end

        product.images = images
        product.price = params[:product][:price]
        product.quantity = params[:product][:quantity]
        product.user_rating = params[:product][:user_rating]
        product.save
        
        if product.errors.full_messages.length > 0
            render json: {msgs: product.errors.full_messages}.to_json, status: 400
        else
            render json: get_product_details_json(product)
        end
    end

    def destroy
        @product.destroy

        render status: 201
    end

    def update  
        emptyReqBodyMsg = "Requires 'product' in request body with fields:"

        for i in Product.attribute_names do
            unless ['_id', 'created_at', 'updated_at', 'category_ids'].include? i
                emptyReqBodyMsg.concat(" " + i + "(optional)")       
            end
        end
        
        unless params[:product]
            return render json: {msg: emptyReqBodyMsg}.to_json, status: 400
        end
        
        @product.title = params[:product][:title].presence || @product.title
        @product.description = params[:product][:description].presence || @product.description
        
        newImages = params[:product][:images].presence
        if newImages != nil
            newImages.map! {|i| i.permit([:fileId, :url]).to_h}
            @product.images = newImages
        end

        @product.price = params[:product][:price].presence || @product.price
        @product.quantity = params[:product][:quantity].presence || @product.quantity
        @product.user_rating = params[:product][:user_rating].presence || @product.user_rating
        @product.save
        
        if @product.errors.full_messages.length > 0
            render json: {msgs: @product.errors.full_messages}.to_json, status: 400
        else
            render json: get_product_details_json(@product)
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