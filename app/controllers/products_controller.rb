class ProductsController < ApplicationController
    before_action :set_product, only: [:show, :destroy, :update]

    def index
        limit = params[:limit] ? params[:limit] : 5
        nextPage = params[:next] ? Time.new(params[:next]) : Time.now.utc

        products = Product.where(:updated_at.lt => nextPage).limit(limit).order_by(updated_at: "desc")
        render json: products
    end

    def show
        render json: @product
    end

    def create
        product = Product.new()
        product.title = params[:product][:title]
        
        images = []

        for i in params[:product][:images] do
            if i.class == ActionController::Parameters
                image = i.permit([:fileId, :url]).to_h
                images.push(image)
            end
        end

        product.images = images
        product.price = params[:product][:price]
        product.quantity = params[:product][:quantity]
        product.save
        
        if product.errors.full_messages.length > 0
            render json: {msgs: product.errors.full_messages}.to_json, status: 400
        else
            render json: product
        end
    end

    def destroy
        @product.destroy

        render status: 201
    end

    def update  
        if !params[:product]
            return render json: {msg: "Requires 'product' in request body"}.to_json, status: 400
        end
        
        @product.title = params[:product][:title].presence || @product.title
        
        newImages = params[:product][:images].presence
        if newImages != nil
            newImages.map! {|i| i.permit([:fileId, :url]).to_h}
            @product.images = newImages
        end

        @product.price = params[:product][:price].presence || @product.price
        @product.quantity = params[:product][:quantity].presence || @product.quantity
        @product.save
        
        if @product.errors.full_messages.length > 0
            render json: {msgs: @product.errors.full_messages}.to_json, status: 400
        else
            render json: @product
        end
    end

    def set_product
        product_instance = Product.find(params[:id])

        if product_instance == nil
            render json: {msg: "Product not found"}.to_json, status: 404
        end

        @product = product_instance
    end
end