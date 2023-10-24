require "jwt_authentication"

class RatingsController < ApplicationController
    include JwtAuthentication

    before_action :authenticate_user, only: [:create]

    def_param_group :score do
        property :average_score, Integer
    end

    api!
    param :product_id, String, :required => true
    param :score, Integer, :required => true
    header 'Authorization', 'Bearer {token}', :required => true
    returns :score, :code => 200
    def create
        user_id = request.env[:current_user]._id
        product = Product.find(params[:product_id])

        if product == nil
            return render status: 404, json: {msg: "Product not found"}
        end

        rating = Rating.where(product_id: product._id, user_id: user_id).first

        if rating == nil
            rating = Rating.new
        end

        rating.user_id = user_id
        rating.product_id = product._id

        rating.score = params[:score]
        rating.save

        if rating.errors.full_messages.length > 0
            return render status: 400, json: {msgs: rating.errors.full_messages}
        end

        product_scores = Rating.where(product_id: product._id).only(:score).map { |rating| rating.score }

        average_score = get_average_score(product_scores)

        product.user_rating = average_score
        product.save

        render json: {average_score: average_score}
    end

    def get_average_score (scoreArr)
        average_score = scoreArr.inject{ |sum, el| sum + el }.to_f / scoreArr.size
        average_score = average_score.round(1)

        average_score
    end
end
