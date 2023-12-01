Rails.application.routes.draw do
  get '/about',  to: 'footer#about'
  get '/terms&conditions',  to: 'footer#package_policy'
  get '/charges&deductions',  to: 'footer#charges'
  get '/privacy_policy',  to: 'footer#privacy_policy'
  get '/payment_policy',  to: 'footer#payment_policy'
  root 'public_pages#welcome'
  get '/group_classes', to: 'public_pages#group_classes'
  get '/signup',  to: 'public_pages#signup'
  post '/signup',  to: 'public_pages#create_account'
  get '/clients/clear_filters', to: 'admin/clients#clear_filters', as: 'clear_client_filters'
  get '/purchases/clear_filters', to: 'admin/purchases#clear_filters', as: 'clear_purchase_filters'
  get '/wkclasses/clear_filters', to: 'admin/wkclasses#clear_filters', as: 'clear_wkclass_filters'
  # note (check this is true) if the 'get' is not before the 'resources', the get purchases/search will be handled by the show method (with params[:id] = 'search')
  get '/purchases/filter', to: 'admin/purchases#filter', as: 'purchase_filter'
  get '/wkclasses/filter', to: 'admin/wkclasses#filter', as: 'wkclass_filter'
  get '/clients/filter', to: 'admin/clients#filter', as: 'client_filter'
  get '/workouts/filter', to: 'admin/workouts#filter', as: 'workout_filter'
  get '/workout_group/:id/instructor_expense_filter', to: 'admin/workout_groups#instructor_expense_filter'
  get '/purchases/client_filter', to: 'admin/purchases#new_purchase_client_filter', as: 'new_purchase_client_filter'
  patch '/purchases/:id/expire', to: 'admin/purchases#expire', as: 'expire_purchase'
  get '/purchases/discount', to: 'admin/purchases#discount'
  get '/purchases/dop_change', to: 'admin/purchases#dop_change'
  get '/superadmin/expenses/filter', to: 'superadmin/expenses#filter'
  get '/products/payment', to: 'admin/products#payment'
  get '/wkclasses/instructor_select', to: 'admin/wkclasses#instructor_select'
  post '/wkclasses/:id/repeat', to: 'admin/wkclasses#repeat', as: 'wkclass_repeat'
  get    '/login',   to: 'auth/sessions#new'
  post   '/login',   to: 'auth/sessions#create'
  delete '/logout',  to: 'auth/sessions#destroy'
  get '/switch_account_role',  to: 'auth/sessions#switch_account_role'
  get    'client/clients/:id/book',   to: 'client/clients#book', as: 'client_book'
  get    'client/package_modification/:id/new_freeze',   to: 'client/package_modification#new_freeze', as: 'client_package_modification_new_freeze'
  get    'client/package_modification/:id/adjust_restart',   to: 'client/package_modification#adjust_restart', as: 'client_package_modification_adjust_restart'
  get    'client/package_modification/:id/transfer',   to: 'client/package_modification#transfer', as: 'client_package_modification_transfer'
  get    'client/package_modification/:id/cancel_freeze',   to: 'client/package_modification#cancel_freeze', as: 'client_package_modification_cancel_freeze'
  get    'client/package_modification/:id/cancel_adjust_restart',   to: 'client/package_modification#cancel_adjust_restart', as: 'client_package_modification_cancel_adjust_restart'
  get    'client/package_modification/:id/cancel_transfer',   to: 'client/package_modification#cancel_transfer', as: 'client_package_modification_cancel_transfer'
  post   'client/clients/:id/buy_freeze',   to: 'client/package_modification#buy_freeze', as: 'client_buy_freeze'
  get    'client/clients/:id/history',   to: 'client/clients#history', as: 'client_history'
  get    'client/clients/:id/buy',   to: 'client/clients#buy', as: 'client_buy'
  get    'client/clients/:id/shop',   to: 'client/clients#shop', as: 'client_shop'
  get    'client/clients/:id/pt',   to: 'client/clients#pt', as: 'client_pt'
  get    'client/clients/:id/challenge',   to: 'client/clients#challenge', as: 'client_challenge'
  get    'client/clients/:id/achievement',   to: 'client/clients#achievement', as: 'client_achievement'
  get    'client/clients/:id/achievements',   to: 'client/clients#achievements', as: 'client_achievements'
  get '/client/timetable', to: 'client/clients#timetable', as: 'client_timetable' 
  get '/footfall', to: 'admin/attendances#footfall'
  get '/timetable', to: 'admin/timetables#show_public', as: 'public_timetable'
  get '/superadmin/regular_expenses/add'
  get '/admin/client_analyze', to: 'admin/clients#analyze', as: 'client_analyze'
  get 'admin/workout_groups/:id/show_workouts', to: 'admin/workout_groups#show_workouts', as: 'show_workouts'
  get 'public_pages/wedontsupport'
  get '/buboo/hearts', to: 'public_pages#hearts'

  
  namespace :admin do
    resources :entries, only: [:new, :edit, :create, :update, :destroy]
    resources :table_times, only: [:new, :edit, :create, :update, :destroy]
    resources :table_days, only: [:new, :edit, :create, :update, :destroy]
    resources :timetables
    resources :accounts, only: [:index, :create, :update]
    resources :adjustments, only: [:new, :edit, :create, :update, :destroy]
    resources :attendances, only: [ :create, :update, :destroy]
    resources :clients
    resources :fitternities
    resources :freezes, only: [:new, :edit, :create, :update, :destroy]
    resources :instructors
    resources :partners
    resources :prices, only: [:new, :edit, :create, :update, :destroy]
    resources :products
    resources :purchases
    resources :wkclasses
    resources :workouts, only: [:index, :new, :edit, :create, :update, :destroy]
    resources :workout_groups
  end
  namespace :superadmin do
    resources :discounts
    resources :discount_reasons
    resources :expenses, only: [:index, :new, :edit, :create, :update, :destroy]
    resources :other_services, only: [:index, :new, :edit, :create, :update, :destroy]
    resources :regular_expenses, only: [:index, :new, :edit, :create, :update, :destroy]
    resources :instructor_rates, only: [:index, :new, :edit, :create, :update, :destroy]
    resource :settings
    resources :orders
    get "refund/:id", to: "orders#refund", as: 'order_refund' 
  end
  # get 'client/clients/:id', to: 'client/clients#show', as: 'client_show'
  namespace :client do
    resources :waitings, only: [:create, :destroy]
    # get 'package_modification/new_freeze'
    resources :clients, only: [:show]
    resources :password_resets, only: [:new, :create, :edit, :update]
  end

  namespace :shared do
    resources :achievements, except: [:show]
    resources :challenges
  end

end