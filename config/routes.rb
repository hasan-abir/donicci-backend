Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  resources :products, only: [:index, :show, :create, :destroy, :update] do
    member do
      put 'categories', to: "products#add_categories"
      put 'categories/remove', to: "products#remove_categories"
    end
  end
end
