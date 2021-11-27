Rails.application.routes.draw do
  resources :wkclasses
  resources :attendances
  resources :instructors
  resources :workouts
  resources :rel_product_workouts
  resources :rel_user_products
  resources :products
  resources :users
  root 'users#index'
end
