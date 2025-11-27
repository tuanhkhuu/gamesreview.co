Rails.application.routes.draw do
  # Static pages
  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy

  # OAuth Authentication Routes
  get "sign_in", to: "sessions#new"
  delete "sign_out", to: "sessions#destroy"

  # OAuth provider callbacks
  get "/auth/:provider/callback", to: "omniauth_callbacks#create"
  get "/auth/failure", to: "omniauth_callbacks#failure"

  # Connected OAuth accounts management
  resources :oauth_identities, only: [ :index, :destroy ]

  # Session management
  resources :sessions, only: [ :index, :show, :destroy ]

  # Account deletion (GDPR compliance)
  delete "account", to: "users#destroy", as: :account

  root "home#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
