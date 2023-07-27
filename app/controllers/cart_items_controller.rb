require "jwt_authentication"

class CartItemsController < ApplicationController
    include JwtAuthentication

    before_action :authenticate_user do
        check_for_roles(["ROLE_ADMIN", "ROLE_MODERATOR", "ROLE_USER"])
    end
    prepend_before_action :set_cart_item, only: [:destroy]
    
    def index
        user_id = request.env[:current_user]._id

        cartItems = CartItem.where(user_id: user_id).only(:_id, :selected_quantity, :product_id)

        cartItems = cartItems.map do |cart_item|
            cart_item.attributes["product_image"] = cart_item.product.images[0]
            cart_item.attributes["product_title"] = cart_item.product.title
            cart_item.attributes["product_price"] = cart_item.product.price
            cart_item.attributes["product_quantity"] = cart_item.product.quantity
            cart_item.attributes.delete("product_id")
            cart_item.attributes
        end

        render json: cartItems
    end

    def create
        emptyReqBodyMsg = "Requires 'item' in request body with fields:"

        for i in CartItem.attribute_names do
            unless ['_id', 'created_at', 'updated_at', 'user_id'].include? i
                    emptyReqBodyMsg.concat(" " + i)       
            end
        end

        unless params[:item]
            return render json: {msg: emptyReqBodyMsg}.to_json, status: 400
        end

        cart_item = CartItem.new

        user_id = request.env[:current_user]._id
        product_id = params[:item][:product_id]
        selected_quantity = params[:item][:selected_quantity]

        cart_item.user_id = user_id

        product = product_id && Product.find(product_id)

        unless product
            return render json: {msg: "Product not found"}, status: 404
        end

        cart_item.product_id = product_id

        unless selected_quantity.to_i <= product.quantity
            return render json: {msg: "Selected quantity exceeds the stock"}, status: 400
        end

        cart_item.selected_quantity = selected_quantity

        cart_item.save        

        if cart_item.errors.full_messages.length > 0
            render json: {msgs: cart_item.errors.full_messages}.to_json, status: 400
        else
            render json: get_cart_item_details_json(cart_item)
        end
    end

    def destroy
        user_id = request.env[:current_user]._id

        unless user_id === @cart_item.user_id
            return render json: {msg: "Unauthorized"}.to_json, status: 403
        end

        @cart_item.destroy

        render status: 201
    end

    def destroy_all
        user_id = request.env[:current_user]._id

        CartItem.destroy_all({:user_id => user_id})

        render status: 201
    end

    def get_cart_item_details_json(cart_item)
        cart_item.attributes["product_image"] = cart_item.product.images[0]
        cart_item.attributes["product_title"] = cart_item.product.title
        cart_item.attributes["product_price"] = cart_item.product.price
        cart_item.attributes["product_quantity"] = cart_item.product.quantity

        cart_item.to_json(only: [:_id, :selected_quantity, :product_image, :product_title, :product_price, :product_quantity])
    end

    def set_cart_item
        cart_item_instance = CartItem.find(params[:id])
    
        if cart_item_instance == nil
            render json: {msg: "Cart item not found"}.to_json, status: 404
        end

        @cart_item = cart_item_instance
    end
end
