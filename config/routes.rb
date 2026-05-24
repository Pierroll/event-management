Rails.application.routes.draw do
  devise_for :users

  # Public pages
  root "home#index"
  resources :events, only: [:index, :show] do
    resources :comments, only: [:create, :destroy]
  end

  # User profile
  resource :profile, only: [:show, :edit, :update]

  # Organizer namespace
  namespace :organizer do
    resources :events
  end

  # Admin namespace
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    resources :users, only: [:index, :show, :edit, :update]
    resources :events, only: [:index, :show, :update]
    resources :categories
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
