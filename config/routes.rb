Rails.application.routes.draw do
  # get 'client/clients/show', to: 'client/clients#show', as: 'client_show'
  get 'public_pages/welcome'
  root 'public_pages#welcome'
  get '/purchases/clear_filters', to: 'admin/purchases#clear_filters', as: 'clear_purchase_filters'
  get '/clients/clear_filters', to: 'admin/clients#clear_filters', as: 'clear_client_filters'
  # note (check this is true) if the 'get' is not before the 'resources', the get purchases/search will be handled by the show method (with params[:id] = 'search')
  get '/purchases/filter', to: 'admin/purchases#filter', as: 'purchase_filter'
  get '/wkclasses/filter', to: 'admin/wkclasses#filter', as: 'wkclass_filter'
  get '/clients/filter', to: 'admin/clients#filter', as: 'client_filter'
  post '/products/payment', to: 'admin/products#payment'
  get    '/login',   to: 'auth/sessions#new'
  post   '/login',   to: 'auth/sessions#create'
  delete '/logout',  to: 'auth/sessions#destroy'
  namespace :admin do
    resources :accounts, only: [:create]
    resources :adjustments, only: [:new, :edit, :create, :update, :destroy]
    resources :attendances, only: [:index, :new, :create, :update, :destroy]
    resources :clients
    resources :fitternities
    resources :freezes, only: [:new, :edit, :create, :update, :destroy]
    resources :instructors, only: [:index, :new, :edit, :create, :update, :destroy]
    resources :partners
    resources :prices, only: [:new, :edit, :create, :update, :destroy]
    resources :products
    resources :purchases
    # resources :rel_workout_group_workouts, only: [:create, :update, :destroy]
    resources :revenues, only: [:index]
    resources :wkclasses
    resources :workouts, only: [:index, :new, :edit, :create, :update, :destroy]
    resources :workout_groups
  end
  namespace :superadmin do
    resources :expenses, only: [:index, :new, :edit, :create, :update, :destroy]
    resources :instructor_rates, only: [:index, :new, :edit, :create, :update, :destroy]
  end
  namespace :client do
    resources :clients, only: [:show]
  end
end
