Rails.application.routes.draw do
  root 'clients#index'
  get '/purchases/clear_filters', to: 'purchases#clear_filters', as: 'clear_filters'
  # note if the 'get' is not before the 'resources', the get purchases/search will be handled by the show method (with params[:id] = 'search')
  get '/purchases/filter', to: 'purchases#filter', as: 'filter'
  get '/wkclasses/filter', to: 'wkclasses#filter'
  post '/products/payment', to: 'products#payment'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  resources :purchases
  resources :clients
  resources :rel_workout_group_workouts
  resources :workout_groups
  resources :wkclasses
  resources :attendances, only: [:index, :new, :create, :destroy]
  resources :instructors, only: [:index, :new, :edit, :create, :update, :destroy]
  resources :workouts, only: [:index, :new, :edit, :create, :update, :destroy]
  resources :workout_groups
  resources :products
  resources :revenues, only: [:index]
  resources :adjustments
  resources :freezes
  resources :fitternities
  resources :prices
  resources :accounts, only: [:index, :create, :destroy]
end
