Rails.application.routes.draw do
  get 'client/clients/show', to: 'client/clients#show', as: 'client_show'
  get 'public_pages/welcome'
  root 'public_pages#welcome'
  get '/purchases/clear_filters', to: 'admin/purchases#clear_filters', as: 'clear_filters'
  # note (check this is true) if the 'get' is not before the 'resources', the get purchases/search will be handled by the show method (with params[:id] = 'search')
  get '/purchases/filter', to: 'admin/purchases#filter', as: 'purchase_filter'
  get '/wkclasses/filter', to: 'admin/wkclasses#filter'
  post '/products/payment', to: 'admin/products#payment'
  get    '/login',   to: 'auth/sessions#new'
  post   '/login',   to: 'auth/sessions#create'
  delete '/logout',  to: 'auth/sessions#destroy'
  namespace :admin do
    resources :accounts, only: [:index, :create, :destroy]
    resources :adjustments, only: [:new, :edit, :create, :update, :destroy]
    resources :attendances, only: [:index, :new, :create, :destroy]
    resources :clients
    resources :fitternities
    resources :freezes, only: [:new, :edit, :create, :update, :destroy]
    resources :instructors, only: [:index, :new, :edit, :create, :update, :destroy]
    resources :prices
    resources :products
    resources :purchases
    resources :rel_workout_group_workouts
    resources :revenues, only: [:index]
    resources :wkclasses
    resources :workouts, only: [:index, :new, :edit, :create, :update, :destroy]
    resources :workout_groups
  end
  namespace :superadmin do
    resources :instructor_salaries
    resources :instructor_rates
  end
end
