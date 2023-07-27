Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  # User authentication routes
  resources :roles, only: [:create, :destroy] do
    member do
      put "user/:username", to: "roles#assign_role"
    end
  end

  scope path: '/auth' do
    post '/register', to: 'users#create'
    post '/login', to: 'sessions#create'
    post '/refresh-token', to: 'sessions#refresh'
    delete '/logout', to: 'sessions#destroy'
  end

  resources :products, only: [:index, :show, :create, :destroy, :update] do
    member do
      put 'categories', to: "products#add_categories"
      put 'categories/remove', to: "products#remove_categories"
    end
  end
  resources :categories
  resources :cart_items, path: "/cart", only: [:index, :create, :destroy] do
    collection do
      delete "/all", to: "cart_items#destroy_all"
    end
  end
  resources :ratings, only: [:create]
  resources :reviews, only: [:create, :destroy] do
    collection do
      get "/product/:product_id", to: "reviews#get_product_reviews"
    end
  end
end  