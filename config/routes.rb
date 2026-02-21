Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]
  resource :profile, only: [ :edit, :update ]

  namespace :admin do
    get "/", to: "dashboard#show", as: :dashboard
    resources :invitations, only: [ :index, :new, :create, :destroy ]
    resources :users, only: [ :index ]
    resources :meetings, only: [ :index, :show, :new, :create, :destroy ]
  end

  resources :meetings, only: [ :index, :show ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"
end
