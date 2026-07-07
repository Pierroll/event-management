Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  # Custom OAuth with role selection (redirects to Google with role in session)
  devise_scope :user do
    post "users/auth/google_oauth2/with_role", to: "users/omniauth_callbacks#authorize_with_role", as: :user_google_oauth2_authorize_with_role
  end

  # Email confirmation
  resource :confirmation, only: [:new, :create], controller: "confirmations" do
    post :verify, on: :collection
    post :resend, on: :collection
  end

  # Public pages
  root "home#index"
  resources :events, only: [:index, :show] do
    post :create_alert, on: :collection
    post :favorite, on: :member
    resources :ecosystem_mocks, only: [:index], module: :events
    resources :comments, only: [:create, :destroy]
    resources :bookings, only: [:new, :create]
  end

  resources :bookings, only: [:index, :show] do
    resources :payments, only: [:new, :create]
  end

  resources :tickets, only: [:update]

  # User profile
  resource :profile, only: [:show, :edit, :update]

  # Developer Portal
  namespace :developers do
    resource :portal, only: [:show] do
      post :regenerate_api_token, on: :collection
    end
  end

  # Organizer namespace
  namespace :organizer do
    resources :events do
      get :attendees, on: :member
      patch :cancel, on: :member
      resource :check_in, only: [:show, :create], controller: "check_ins" do
        get :search
      end
    end
  end

  # Admin namespace
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    resources :users, only: [:index, :show, :edit, :update]
    resources :events, only: [:index, :show, :edit, :update]
    resources :categories
  end

  # Webhooks
  namespace :webhooks do
    resources :payments, only: [], controller: :payments do
      post :receive, on: :collection
    end
  end

  # API B2B
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :events, only: [:index, :show]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
