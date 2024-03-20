Rails.application.routes.draw do
  # root 'public_pages/home#welcome'
  # https://stackoverflow.com/questions/65794152/how-can-i-do-a-health-check-for-a-rails-based-app-on-render
  get '/health_check', to: proc { [200, {}, ['success']] }
  # whereas below from railsguide3.13 doesnt work
  # get '/health', to: ->(env) { [204, {}, ['']] }
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
  # get    'client/clients/:id/challenge',   to: 'client/clients#challenge', as: 'client_challenge'
  get    'client/clients/:id/achievement',   to: 'client/clients#achievement', as: 'client_achievement'
  get    'client/clients/:id/achievements',   to: 'client/clients#achievements', as: 'client_achievements'
  get '/client/timetable', to: 'client/clients#timetable', as: 'client_timetable' 

  # https://guides.rubyonrails.org/routing.html 2.10 Adding More RESTful Actions...2.10.2 Adding Collection Routes
  scope module: :admin do
    # principle correct but example routes need updating
    # if say get 'admin/purchases/filter' was after the (admin namespaced) resources :purchases, a request to admin/purchases/filter would be handled by the show method of the purchases controller (with params[:id] = 'filter')
    # and an error would arise 'ActiveRecord::RecordNotFound (Couldn't find Purchase with 'id'=filter):'. This happens due to https://guides.rubyonrails.org/routing.html section 2.2
    # the first match of the url 'admin/purchases/filter' would be /admin/purchases/:id(.:format), handled by the show method. The admin/purchases/filter(.:format) would be ignored as it comes later.
    get '/purchases/client_filter', to: 'purchases#new_purchase_client_filter', as: 'new_purchase_client_filter'
    patch '/purchases/:id/expire', to: 'purchases#expire', as: 'expire_purchase'
    get '/purchases/discount' #, to: 'purchases#discount'
    get '/purchases/dop_change' #, to: 'purchases#dop_change'
    get '/workout_groups/:id/instructor_expense_filter', to: 'workout_groups#instructor_expense_filter', as: 'instructor_expense_filter'
    get '/wkclasses/instructor_select' #, to: 'wkclasses#instructor_select'
    get '/footfall', to: 'attendances#footfall'
    get '/timetable', to: 'timetables#show_public', as: 'public_timetable'
    get 'client_analyze', to: 'clients#analyze', as: 'client_analyze'
    get 'workout_groups/:id/show_workouts', to: 'workout_groups#show_workouts', as: 'show_workouts'      
    post '/timetable/:id/copy', to: 'timetables#deep_copy', as: 'timetable_deep_copy'  
    post '/wkclasses/:id/repeat', to: 'wkclasses#repeat', as: 'wkclass_repeat'    
    resources :clients, :products, :purchases, :wkclasses do
      # get 'filter', on: :collection
      collection do
        get 'filter'
        get 'clear_filters'
      end      
    end
    resources :freezes, :workouts, except: [:show] do
      get 'filter', on: :collection
    end
    resources :adjustments, :entries, :prices, except: [:index, :show]
    resources :accounts, only: [:index, :create, :update, :destroy]
    resources :attendances, only: [ :new, :create, :update, :destroy]
    resources :fitternities, :instructors, :partners, :timetables, :workout_groups
    resources :restarts, except: [:show] 
    resources :table_times, :table_days, except: [:index, :show]
  end
  
  namespace :superadmin do
    resource :settings, only:[:show, :create]
  end

  # https://guides.rubyonrails.org/routing.html section 2.6 namespaces & routing
  # routes to a superadmin namespaced controller, but doesn't include superadmin in the url or url helper
  scope module: :superadmin do
    post 'regular_expenses/add'
    resource :blast, only: [:show] do 
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
    resources :instructor_rates, :other_services, :regular_expenses, except: [:show]    
    resources :payments, only: [:index, :show, :edit, :update, :destroy] do
      collection do
        get 'filter'
        get 'clear_filters'
      end
    end
    resources :expenses, except: [:show] do
      get 'filter', on: :collection
    end    
  end

  scope module: :auth do
    get    '/login',   to: 'sessions#new'
    post   '/login',   to: 'sessions#create'
    delete '/logout',  to: 'sessions#destroy'
    get '/switch_account_role',  to: 'sessions#switch_account_role'
  end

  # get 'client/clients/:id', to: 'client/clients#show', as: 'client_show'
  namespace :client do
    resources :waitings, only: [:create, :destroy]
    # get 'package_modification/new_freeze'
    resources :clients, only: [:show]
    resources :password_resets, only: [:new, :create, :edit, :update]
  end

  scope module: :shared do
    resources :achievements, except: [:show]    
    resources :body_markers, :strength_markers, except: [:show] do
      get 'filter', on: :collection
    end
    resources :challenges
  end  

  scope module: :public_pages do
    root 'home#welcome'
    get '/about',  to: 'footer#about'
    get '/terms_and_conditions',  to: 'footer#package_policy'
    get '/charges_and_deductions',  to: 'footer#charges'
    get '/privacy_policy',  to: 'footer#privacy_policy'
    get '/payment_policy',  to: 'footer#payment_policy'
    get '/group_classes', to: 'home#group_classes'
    get '/signup',  to: 'home#signup'
    post '/signup',  to: 'home#create_account'
    get '/chootiya', to: 'home#wedontsupport'
    get '/buboo', to: 'home#hearts'
  end  

end

