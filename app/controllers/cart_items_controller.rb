require "jwt_authentication"

class CartItemsController < ApplicationController
    include JwtAuthentication

    before_action :authenticate_user do
        check_for_roles(["ROLE_ADMIN", "ROLE_MODERATOR", "ROLE_USER"])
    end
    prepend_before_action :set_cart_item, only: [:destroy]
    
    def index
        user_id = request.env[:current_user]._id

        cartItems = CartItem.where(user_id: user_id)

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

        cartItem = CartItem.new

        user_id = request.env[:current_user]._id
        product_id = params[:item][:product_id]
        selected_quantity = params[:item][:selected_quantity]

        cartItem.user_id = user_id

        product = product_id && Product.find(product_id)

        unless product
            return render json: {msg: "Product not found"}, status: 404
        end

        cartItem.product_id = product_id

        unless selected_quantity.to_i <= product.quantity
            return render json: {msg: "Selected quantity exceeds the stock"}, status: 400
        end

        cartItem.selected_quantity = selected_quantity

        cartItem.save        

        if cartItem.errors.full_messages.length > 0
            render json: {msgs: cartItem.errors.full_messages}.to_json, status: 400
        else
            render json: cartItem
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

    def set_cart_item
        cart_item_instance = CartItem.find(params[:id])
    
        if cart_item_instance == nil
            render json: {msg: "Cart item not found"}.to_json, status: 404
        end

        @cart_item = cart_item_instance
    end
end
