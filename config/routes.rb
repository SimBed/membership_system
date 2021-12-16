Rails.application.routes.draw do
  root 'clients#index'
  resources :purchases
  resources :clients
  resources :rel_workout_group_workouts
  resources :workout_groups
  resources :wkclasses
  resources :attendances, only: [:index, :new, :create, :destroy]
  resources :instructors
  resources :workouts
  resources :workout_groups
  resources :products
  resources :revenues, only: [:index]
  resources :adjustments
  resources :freezes
end
