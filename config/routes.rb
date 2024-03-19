Rails.application.routes.draw do
  # https://stackoverflow.com/questions/65794152/how-can-i-do-a-health-check-for-a-rails-based-app-on-render
  get '/health_check', to: proc { [200, {}, ['success']] }
  # whereas below from railsguide3.13 doesnt work
  # get '/health', to: ->(env) { [204, {}, ['']] }
  root 'public_pages/home#welcome'
  # get '/about',  to: 'public_pages/footer#about'
  # get '/terms_and_conditions',  to: 'public_pages/footer#package_policy'
  # get '/charges_and_deductions',  to: 'public_pages/footer#charges'
  # get '/privacy_policy',  to: 'public_pages/footer#privacy_policy'
  # get '/payment_policy',  to: 'public_pages/footer#payment_policy'
  # get '/group_classes', to: 'public_pages/home#group_classes'
  # get '/signup',  to: 'public_pages/home#signup'
  # post '/signup',  to: 'public_pages/home#create_account'
  # get '/chootiya', to: 'public_pages/home#wedontsupport'
  # get '/buboo', to: 'public_pages/home#hearts'
  # get '/clients/clear_filters', to: 'admin/clients#clear_filters', as: 'clear_client_filters'
  # get '/purchases/clear_filters', to: 'admin/purchases#clear_filters' #, as: 'clear_purchase_filters'
  # get '/payments/clear_filters', to: 'superadmin/payments#clear_filters', as: 'clear_payments_filters'
  # if say get 'admin/purchases/filter' was after the (admin namespaced) resources :purchases, a request to admin/purchases/filter would be handled by the show method of the purchases controller (with params[:id] = 'filter')
  # and an error would arise 'ActiveRecord::RecordNotFound (Couldn't find Purchase with 'id'=filter):'. This happens due to https://guides.rubyonrails.org/routing.html section 2.2
  # the first match of the url 'admin/purchases/filter' would be /admin/purchases/:id(.:format), handled by the show method. The admin/purchases/filter(.:format) would be ignored as it comes later.
  # get '/purchases/filter', to: 'admin/purchases#filter' #, as: 'purchase_filter'
  # get '/clients/filter', to: 'admin/clients#filter', as: 'client_filter'
  # get '/payments/filter', to: 'superadmin/payments#filter', as: 'payment_filter'
  # get '/freezes/filter', to: 'admin/freezes#filter', as: 'freeze_filter'
  # get '/wkclasses/filter', to: 'admin/wkclasses#filter', as: 'wkclass_filter'
  # get '/wkclasses/clear_filters', to: 'admin/wkclasses#clear_filters', as: 'clear_wkclass_filters'
  # get '/products/filter', to: 'admin/products#filter', as: 'product_filter'
  # get '/product/clear_filters', to: 'admin/products#clear_filters', as: 'clear_product_filters'
  # get '/workouts/filter', to: 'admin/workouts#filter', as: 'workout_filter'
  # get '/strength_markers/filter', to: 'shared/strength_markers#filter', as: 'strength_marker_filter'
  # get '/body_markers/filter', to: 'shared/body_markers#filter', as: 'body_marker_filter'
  # get '/superadmin/expenses/filter', to: 'superadmin/expenses#filter'
  get '/workout_group/:id/instructor_expense_filter', to: 'admin/workout_groups#instructor_expense_filter'
  get '/purchases/client_filter', to: 'admin/purchases#new_purchase_client_filter', as: 'new_purchase_client_filter'
  patch '/purchases/:id/expire', to: 'admin/purchases#expire', as: 'expire_purchase'
  get '/purchases/discount', to: 'admin/purchases#discount'
  get '/purchases/dop_change', to: 'admin/purchases#dop_change'
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
  # get    'client/clients/:id/challenge',   to: 'client/clients#challenge', as: 'client_challenge'
  get    'client/clients/:id/achievement',   to: 'client/clients#achievement', as: 'client_achievement'
  get    'client/clients/:id/achievements',   to: 'client/clients#achievements', as: 'client_achievements'
  get '/client/timetable', to: 'client/clients#timetable', as: 'client_timetable' 
  get '/footfall', to: 'admin/attendances#footfall'
  get '/timetable', to: 'admin/timetables#show_public', as: 'public_timetable'
  post '/timetable/:id/copy', to: 'admin/timetables#deep_copy', as: 'timetable_deep_copy'
  get '/superadmin/regular_expenses/add'
  get '/admin/client_analyze', to: 'admin/clients#analyze', as: 'client_analyze'
  get 'admin/workout_groups/:id/show_workouts', to: 'admin/workout_groups#show_workouts', as: 'show_workouts'


  
  # namespace :admin do
    # resources :fitternities, :instructors, :partners, :timetables, :workout_groups
    # resources :accounts, only: [:index, :create, :update, :destroy]
    # resources :adjustments, except: [:index, :show]
    # resources :attendances, only: [ :new, :create, :update, :destroy]
    # resources :entries, except: [:index, :show]
    # resources :freezes, except: [:show]
    # resources :prices, except: [:index, :show]
    # resources :restarts, except: [:show]
    # resources :table_times, except: [:index, :show]
    # resources :table_days, except: [:index, :show]
    # resources :workouts, except: [:show]
  # end
  
  # https://guides.rubyonrails.org/routing.html 2.10 Adding More RESTful Actions...2.10.2 Adding Collection Routes
  scope module: :admin do
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
    # get 'blasts/new'
    # get 'blasts/filter', to: 'blasts#filter', as: 'blast_filter'
    # get 'blasts/clear_filters', to: 'blast#clear_filters', as: 'clear_blast_filters'
    # post 'message/add_message', to: 'blast#add_message', as: 'add_message'
    # get 'blast/test_blast', to: 'blast#test_blast', as: 'test_blast'
    # get 'blast/blast_off', to: 'blast#blast_off', as: 'blast_off'
    # get 'blast/remove_client/:id', to: 'blast#remove_client', as: 'remove_client'
    # get 'blast/add_client', to: 'blast#add_client', as: 'add_client'
    resource :settings, only:[:show, :create]
    # resources :discounts
    # resources :payments, only: [:index, :show, :edit, :update, :destroy]
    # resources :discount_reasons
    # resources :expenses, except: [:show]
    # resources :other_services, except: [:show]
    # resources :regular_expenses, except: [:show]
    # resources :instructor_rates, except: [:show]
    # resources :orders
    # get "refund/:id", to: "orders#refund", as: 'order_refund'
  end

  # https://guides.rubyonrails.org/routing.html section 2.6 namespaces & routing
  # routes to a superadmin namespaced controller, but doesn't include superadmin in the url or url helper
  scope module: :superadmin do
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

  # get 'client/clients/:id', to: 'client/clients#show', as: 'client_show'
  namespace :client do
    resources :waitings, only: [:create, :destroy]
    # get 'package_modification/new_freeze'
    resources :clients, only: [:show]
    resources :password_resets, only: [:new, :create, :edit, :update]
  end

  # namespace :shared do
    # resources :strength_markers, except: [:show]
    # resources :body_markers, except: [:show]
    # resources :achievements, except: [:show]
    # resources :challenges
  # end

  scope module: :shared do
    resources :achievements, except: [:show]    
    resources :body_markers, :strength_markers, except: [:show] do
      get 'filter', on: :collection
    end
    resources :challenges
  end  

  scope module: :public_pages do
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

