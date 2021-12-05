Rails.application.routes.draw do
  root 'users#index'
  resources :purchases
  resources :clients
  resources :rel_workout_group_workouts
  resources :workout_groups
  resources :wkclasses
  resources :attendances
  resources :instructors
  resources :workouts
  resources :workout_groups
  resources :products
  resources :revenues, only: [:index]
end
