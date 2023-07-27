require "jwt_authentication"

class ReviewsController < ApplicationController
    include JwtAuthentication

    before_action :authenticate_user, only: [:create, :destroy]
    prepend_before_action :set_review, only: [:destroy]

    def get_product_reviews
        limit = params[:limit] ? params[:limit] : 5
        nextPage = params[:next] ? Time.new(params[:next]) : Time.now.utc
        
        product = Product.find(params[:product_id])

        if product == nil
            return render status: 404, json: {msg: "Product not found"}
        end

        reviews = Review.where(:updated_at.lt => nextPage).limit(limit).only(:_id, :description, :user_id).order_by(updated_at: "desc")

        reviews = reviews.map do |review|
            review.attributes["author"] = review.user.display_name

            review.attributes.delete("user_id")

            review.attributes
        end

        render json: reviews
    end

    def create
        user_id = request.env[:current_user]._id
        product = Product.find(params[:product_id])

        if product == nil
            return render status: 404, json: {msg: "Product not found"}
        end

        review = Review.new
        review.user_id = user_id
        review.product_id = product._id

        review.description = params[:description]

        review.save

        if review.errors.full_messages.length > 0
            return render status: 400, json: {msgs: review.errors.full_messages}
        end

        render json: get_review_details_json(review)
    end

    def destroy
        if @review.user_id != request.env[:current_user]._id
            return render status: 403, json: {msg: "Unauthorized"}
        end
        
        @review.destroy
        
        render status: 201
    end

    def get_review_details_json(review, display_name = nil)
        review.attributes["author"] = display_name || request.env[:current_user].display_name

        review.to_json(only: [:_id, :description, :author])
    end

    def set_review
        review_instance = Review.find(params[:id])
    
        if review_instance == nil
            render json: {msg: "Review not found"}.to_json, status: 404
        end

        @review = review_instance
    end
end
