Rails.application.routes.draw do
  resources :rel_workout_group_workouts
  resources :workout_groups
  resources :wkclasses
  resources :attendances
  resources :instructors
  resources :workouts
  resources :workout_groups
  resources :rel_user_products
  resources :products
  resources :users
  root 'users#index'
end
