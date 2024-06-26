Rails.application.routes.draw do
  # root 'public_pages/home#welcome'
  # https://stackoverflow.com/questions/65794152/how-can-i-do-a-health-check-for-a-rails-based-app-on-render
  get '/health_check', to: proc { [200, {}, ['success']] }
  # whereas below from railsguide3.13 doesnt work
  # get '/health', to: ->(env) { [204, {}, ['']] }

  # https://guides.rubyonrails.org/routing.html 2.10 Adding More RESTful Actions...2.10.2 Adding Collection Routes
  scope module: :admin do
    # principle correct but example routes need updating
    # if say get 'admin/purchases/filter' was after the (admin namespaced) resources :purchases, a request to admin/purchases/filter would be handled by the show method of the purchases controller (with params[:id] = 'filter')
    # and an error would arise 'ActiveRecord::RecordNotFound (Couldn't find Purchase with 'id'=filter):'. This happens due to https://guides.rubyonrails.org/routing.html section 2.2
    # the first match of the url 'admin/purchases/filter' would be /admin/purchases/:id(.:format), handled by the show method. The admin/purchases/filter(.:format) would be ignored as it comes later.
    get '/purchases/client_filter', to: 'purchases#client_filter', as: 'client_filter'
    patch '/purchases/:id/expire', to: 'purchases#expire', as: 'expire_purchase'
    # get '/purchases/discount'
    # get '/purchases/dop_change'
    # get '/workout_groups/:id/instructor_expense_filter', to: 'workout_groups#instructor_expense_filter', as: 'instructor_expense_filter'
    get '/wkclasses/instructor_select'
    get '/footfall', to: 'bookings#footfall'
    get '/timetable', to: 'timetables#public_format', as: 'public_format_timetable'
    # get 'client_analyze', to: 'clients#analyze', as: 'client_analyze'
    # get 'workout_groups/:id/show_workouts', to: 'workout_groups#show_workouts', as: 'show_workouts'
    post '/timetable/:id/copy', to: 'timetables#deep_copy', as: 'timetable_deep_copy'
    post '/wkclasses/:id/repeat', to: 'wkclasses#repeat', as: 'wkclass_repeat'
    resources :products, :wkclasses, :workouts do
      # get 'filter', on: :collection
      collection do
        get 'filter'
        get 'clear_filters'
      end
    end
    resources :purchases do
      collection do
        get 'filter'
        get 'clear_filters'
        get 'discount'
        get 'form_field_change'        
      end
    end
    resources :clients do
      collection do
        get 'filter'
        get 'clear_filters'
        get 'analyze'        
      end
    end
    resources :freezes, except: [:show] do
      get 'filter', on: :collection
    end
    resources :workout_groups do
      collection do
        get ':id/instructor_expense_filter', to: 'workout_groups#instructor_expense_filter', as: 'instructor_expense_filter'
        get ':id/show_workouts', to: 'workout_groups#show_workouts', as: 'show_workouts'
        patch 'toggle_current/:id', to: 'workout_groups#toggle_current', as: 'toggle_current'
      end
    end
    resources :adjustments, :entries, :prices, except: [:index, :show]
    resources :accounts, only: [:create, :update, :destroy]
    # an update of a booking is handled by the booking cancellations controller (not the bookings controller)
    resources :bookings, only: [:new, :create, :destroy]
    resources :booking_cancellations, only: :update
    resources :fitternities, :instructors, :partners, :timetables
    resources :restarts, except: :show
    resources :table_times, :table_days, except: [:index, :show]
  end

  namespace :superadmin do
    resource :settings, only: [:show, :create]
  end

  # https://guides.rubyonrails.org/routing.html section 2.6 namespaces & routing
  # routes to a superadmin namespaced controller, but doesn't include superadmin in the url or url helper
  scope module: :superadmin do
    post 'regular_expenses/add'
    resource :blast, only: :show do
      collection do
        get 'add_client'
        get 'remove_client/:id', to: 'blasts#remove_client', as: 'remove_client'
        get 'blast_off'
        get 'clear_filters'
        get 'filter'
        get 'test'
        post 'add_message'
      end
    end
    resources :discounts, :discount_reasons, :orders
    resources :employee_accounts do
      collection do
        get 'add_role/:id', to: 'employee_accounts#add_role', as: 'add_role'
        get 'remove_role/:id', to: 'employee_accounts#remove_role', as: 'remove_role'
        patch 'password_reset_of_employee/:id', to: 'employee_accounts#password_reset_of_employee', as: 'password_reset'
      end
    end
    resources :instructor_rates, :other_services, :regular_expenses, except: [:show]
    resources :payments, only: [:index, :show, :edit, :update, :destroy] do
      collection do
        get 'filter'
        get 'clear_filters'
      end
    end
    resources :expenses, except: :show do
      get 'filter', on: :collection
    end
  end

  scope module: :auth do
    get    '/login',   to: 'sessions#new'
    post   '/login',   to: 'sessions#create'
    delete '/logout',  to: 'sessions#destroy'
    get '/switch_account_role', to: 'sessions#switch_account_role'
    # hack to simulate closing a browser used only for integration testing (as sessions can't be directly amended in integration tests)
    get '/close_the_browser',  to: 'sessions#close_the_browser'
  end

  scope module: :client do
    get 'profile/:id', to: 'data_pages#profile', as: :client_profile
  end

  namespace :client do
    get '/:id/shop', to: 'dynamic_pages#shop', as: 'shop'
    get '/:id/history', to: 'data_pages#history', as: 'history'
    # temporarily retain this route and redirect to client_bookings_path
    get '/:id/book', to: 'dynamic_pages#book', as: 'book'
    get '/:id/pt', to: 'data_pages#pt', as: 'pt'
    get '/timetable', to: 'data_pages#timetable', as: 'timetable'
    get '/:id/achievement', to: 'data_pages#achievement', as: 'achievement'
    get '/:id/achievements', to: 'data_pages#achievements', as: 'achievements'
    get ':id/new_freeze', to: 'package_modification#new_freeze', as: 'package_modification_new_freeze'
    get ':id/adjust_restart', to: 'package_modification#adjust_restart', as: 'package_modification_adjust_restart'
    get ':id/transfer', to: 'package_modification#transfer', as: 'package_modification_transfer'
    get ':id/cancel_freeze', to: 'package_modification#cancel_freeze', as: 'package_modification_cancel_freeze'
    get ':id/cancel_adjust_restart', to: 'package_modification#cancel_adjust_restart', as: 'package_modification_cancel_adjust_restart'
    get ':id/cancel_transfer', to: 'package_modification#cancel_transfer', as: 'package_modification_cancel_transfer'
    post ':id/buy_freeze', to: 'package_modification#buy_freeze', as: 'buy_freeze'
    get ':id/bookings', to: 'bookings#index', as: 'bookings'
    post ':id/bookings', to: 'bookings#create', as: 'create_booking'
    # $app.client_update_booking_path(Client.first, Client.first.bookings.last)
    # => "/client/1/booking_cancellations/1668"
    patch ':client_id/booking_cancellations/:id', to: 'booking_cancellations#update', as: 'update_booking'
    # resources :booking_cancellations, only: :update    
    resources :waitings, only: [:create, :destroy]
    resources :password_resets, only: [:new, :create, :edit, :update] do
      collection do
        # TODO: should be patch
        get 'password_change/:id', to: 'password_resets#password_change', as: 'password_change'
      end
    end
  end

  scope module: :shared do
    resources :achievements, except: [:show]
    resources :body_markers, :strength_markers, except: [:show] do
      get 'filter', on: :collection
    end
    resources :challenges
    resources :client, only: [] do # already have the client resource routes in the admin module, dont want an extra set handled by a shared/clients controller
      # the declaration is created from a form scoped to an exisiting client, so the form defaults to a patch (update request) (with nested attributes for  the new declaration)
      # so we only have an update route, not a create route
      # we cannot edit or destroy declarations through the UI
      resource :declaration, only: [:new, :show, :update] do
        resources :declaration_updates, except: [:index] 
      end
    end
    resources :declarations, only: [:index] do # we want an index of all declarations (not an index of each clients declarations)  
      collection do
        get 'filter'
        get 'clear_filters'
      end
    end
    end

  scope module: :public_pages do
    root 'home#welcome'
    get '/about', to: 'footer#about'
    get '/terms_and_conditions', to: 'footer#package_policy'
    get '/charges_and_deductions', to: 'footer#charges'
    get '/privacy_policy',  to: 'footer#privacy_policy'
    get '/payment_policy',  to: 'footer#payment_policy'
    get '/contact',  to: 'footer#contact'
    get '/group_classes', to: 'home#group_classes'
    get '/signup', to: 'home#signup'
    post '/signup',  to: 'home#create_account'
    get '/chootiya', to: 'home#wedontsupport'
    get '/buboo', to: 'home#hearts'
  end
end
