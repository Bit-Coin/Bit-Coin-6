require 'resque/server'

Rails.application.routes.draw do

  # Status checks
  ######################################################
  get 'status/summary', to: 'status#summary'
  ######################################################

  # Devise
  ######################################################
  devise_for :users, format: false, controllers: {
    registrations: 'users/registrations',
    passwords: 'users/passwords', # only for resets.  change password through profiles
    confirmations: 'users/confirmations',
    sessions: 'users/sessions'
  }

  devise_scope :user do
    # STEP 1:  give us the email you want to use
    get '/register/email', to: 'users/registrations#register_email',
      as: :register_email
    post 'register/email', to: 'users/registrations#create_user_stub'

    # STEP 1a: Confirm email...

    # STEP 2: If the email is not on the list of registered domains
    get '/contact/:id/register', to: 'users/registrations#contact_form',
      as: :contact_form
    put '/contact/:id/register', to: 'users/registrations#create_pending_registration',
      as: :register_contact

    # STEP 2: If the email is on the list of registered domains
    get '/rippler/:id/register', to: 'users/registrations#rippler_form', as: :rippler_form
    put '/rippler/:id/register', to: 'users/registrations#create_rippler_registration',
      as: :register_rippler

    # STEP 3: After register contact
    get '/contact/:id/thank_you', to: 'users/registrations#thank_you', as: :thank_you_contact

    # STEP 3: After register rippler
    get '/login', to: 'users/sessions#new', as: :login
    post '/users/sessions', to: 'users/sessions#create'

    get '/set_subdomain', to: 'users/sessions#set_subdomain', as: :set_subdomain
    post '/find_login', to: 'users/sessions#find_login', as: :find_login
    get '/forgot_login_domain', to: 'users/sessions#forgot_login_domain', as: :forgot_login_domain
    post '/remind_login_domain', to: 'users/sessions#remind_login_domain', as: :remind_login_domain

    delete '/users/sessions', to: 'users/sessions#destroy'

    # Other
    get '/user/:id/resend_surveys', to: 'users/registrations#resend_surveys',
      as: :user_resend_surveys
  end

  devise_for :admins, controllers: { registrations: 'admins/registrations' }
  devise_scope :admin do
    get '/admin/:id/edit', to: 'admins/registrations#edit', as: :edit_admin
  end

  # User routes
  namespace :user do
    get '/reports', to: 'reports#index'
    get '/team-reports', to: 'reports#team_reports'
    get '/executive_report', to: 'reports#executive_report'
  end

  # Admin routes
  ######################################################
  namespace :admin do
    mount RailsAdmin::Engine => '/rails', as: 'rails_admin'

    authenticate :admin do
      mount Resque::Server.new, :at => "/resque"
    end

    resources :companies do
      resources :subscriptions do
        member do
          get 'upgrade'
          post 'transact'
        end
      end
      member do
        get 'edit_config'
        get 'new_maven'
        get 'new_executive'
        post 'add_executive'
        post 'update_config'
        post 'bulk_create_users'
        post 'connect_users'
        post 'create_team'
        post 'assign_team'
        post 'assign_team_manager'
        post 'change_user_state'
        post 'generate_self_survey'
      end
      collection do
        post 'update_development_tools'
        post 'update_maven'
      end
    end

    # TODO rename controllers & routes
    resources :invitations, only: [:index, :destroy] do
      collection do
        get 'stale'
        get 'status'
      end
      member { get 'resend' }
    end

    get :dead_letters, controller: 'messages'
    get :system_events, controller: 'events'
    get :system_reports, controller: 'reports'
    get :user_reports, controller: 'reports'
    get :impression_count, controller: 'reports'
    get 'system_reports/:user_id', to: 'reports#user_system_reports', as: :user_system_reports
    get 'system_reports/:user_id/questions', to: 'reports#questions', as: :questions


    resources :teams
    resources :queues
    resources :response_sets
    resources :questions do
      member do
        get 'check_responses'
      end
    end
    resources :characteristics do
      member do
        get 'components', to: 'characteristics#edit_components', as: :component
        get 'questions', to: 'characteristics#edit_questions'
        get 'edit_component', to: 'characteristics#edit_component', as: :edit_component
      end
    end
    resources :survey_sets
    resources :survey_set_questions
    resources :survey_series
    resources :company_survey_series
    resources :roles

    get 'users/new_contact', to: 'users#new_contact'
    post 'users/create_contact', to: 'users#create_contact'

    resources :users do
      post :set_feedback_option, on: :member
      collection do
        get 'prospects'
        get 'reminders'
        get 'team_leaders'

        get ':user_id', to: 'users#edit'
        get 'edit_password/:user_id', to: 'users#edit_password'

        patch 'update', to: 'users#update', as: :admin_user_update
        patch 'update_password', to: 'users#update_password', as: :admin_user_update_password



      end
      member do
        get 'test_drive'
        get 'new_company'
        post 'create_company'
        post 'connect_test_driver'
        delete 'destroy'
      end
    end

    get '', to: 'dashboards#show'

    resources :blogs

  end

  delete '/admin/users/:id/destroy_final', to: 'admin/users#destroy_final'

  post 'proxy/become_proxy/:user_id', to: 'proxy#become_proxy', as: :become_proxy
  post 'proxy/become_admin/', to: 'proxy#become_admin', as: :become_admin

  # API routes
  ######################################################
  namespace :api do
    namespace :v1 do
      get :widgets, controller: 'widgets'
      get :scores, controller: 'scores'
      get :demo_data, controller: 'scores'
      post :survey_response, controller: 'responses'
      # TODO change invitation to survey_plan
      resources :invitations, only: [:update, :create, :destroy] do
        member { get 'resend' }
      end
      post :mail_event, controller: 'mail_events'
    end
  end

  # Application routes
  ######################################################
  get 'surveys/next', to: 'surveys#next_survey', as: :next_survey
  get 'surveys/self', to: 'surveys#self_survey', as: :self_survey
  resources :surveys, only: [:index, :edit] do
    member { put 'complete' }
    member { get 'done' }
    member { put 'decline' }
  end
  resources :companies, only: [:update]

  get 'development_tools/development_tools', to: 'development_tools#development_tools', as: 'development_tools'
  get 'development_tools/curious', to: 'development_tools#curious', as: 'curious'
  get 'development_tools/conscientious', to: 'development_tools#conscientious', as: 'conscientious'
  get 'development_tools/committed', to: 'development_tools#committed', as: 'committed'
  get 'development_tools/cooperative', to: 'development_tools#cooperative', as: 'cooperative'
  get 'development_tools/consistent', to: 'development_tools#consistent', as: 'consistent'
  get 'development_tools/management', to: 'development_tools#management', as: 'management'
  get 'development_tools/executive', to: 'development_tools#executive', as: 'executive'

  get 'profile/edit_profile', to: 'profiles#edit_profile', as: 'edit_profile'
  patch 'profile/profile', to: 'profiles#update_profile', as: 'update_profile'
  get 'profile/edit_password', to: 'profiles#edit_password', as: 'edit_password'
  patch 'profile/password', to: 'profiles#update_password', as: 'update_password'
  get 'profile/teams', to: 'profiles#teams', as: 'teams'
  post 'profile/disable_dashboard', to: 'profiles#disable_dashboard', as: 'disable_dashboard'


  get 'dashboard', to: 'dashboards#show'
  get 'dashboard/questions', to: 'dashboards#questions', as: 'dashboard_questions'
  get 'dashboard/history', to: 'dashboards#history', as: 'dashboard_history'


  get 'invitations/manage', to: 'invitations#manage', as: 'manage_invitations'
  get 'invitations/:action', controller: 'invitations'
  resources :invitations, :only => [:index, :create, :update, :delete]

  get 'pages/iphone', to: 'pages#iphone'
  get 'pages/terms_and_conditions', to: 'pages#terms_and_conditions'
  get 'pages/privacy_policy', to: 'pages#privacy_policy'
  get 'pages/faq', to: 'pages#faq'
  get 'pages/board-of-trustees', to: 'pages#board_of_trustees'
  get 'pages/board-of-advisors', to: 'pages#board_of_advisors'
  get 'pages/ripple_innovative', to: 'pages#ripple_innovative'
  get '/blogs', to: 'pages#blogs'
  get '/blogs/:id', to: 'pages#blog', as: 'blog'





  resources :subscriptions, only: [:show, :destroy] do
    member do
      get 'upgrade'
      post 'update_subscription'
      get 'pay'
      post 'update_payment'
    end
  end

  post 'stripe_webhooks/invoice_events', to: 'stripe_webhooks#invoice_events'

  root to: 'pages#home'

  if Rails.env.development?
    get '/rails/mailers' => "rails/mailers#index"
    get '/rails/mailers/*path' => "rails/mailers#preview"
  end

  # Swallow annoying favicon requests from ill-behaved mobile devices
  # favicon_link_tag is supposed to tell them where to look, but
  # sometimes they don't listen.
  get 'favicon', :to => 'short_paths#swallow'
  get 'favicon.ico', :to => 'short_paths#swallow'
  get 'apple-touch-icon-precomposed', :to => 'short_paths#swallow'
  get 'apple-touch-icon-precomposed.png', :to => 'short_paths#swallow'
  get 'apple-touch-icon', :to => 'short_paths#swallow'
  get 'apple-touch-icon.png', :to => 'short_paths#swallow'

  # catchall:  /xZyml74 -> user survey page
  get '*short_path', :to => 'short_paths#redirect_to_expanded_path', as: :short

end
