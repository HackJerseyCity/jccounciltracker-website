Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]
  resource :signup, only: [ :new, :create ]
  resource :profile, only: [ :edit, :update ]

  namespace :admin do
    get "/", to: "dashboard#show", as: :dashboard
    resources :invitations, only: [ :index, :new, :create, :destroy ]
    resources :users, only: [ :index ]
    resources :audit_logs, only: [ :index ]
    resources :meetings, only: [ :index, :show, :new, :create, :destroy ] do
      post :import_minutes, on: :member
      delete :delete_minutes, on: :member
      post :publish, on: :member
      get :preview_agenda, on: :member
      post :apply_agenda, on: :member
      get :reupload_agenda, on: :member
      post :auto_tag, on: :member
    end
    resources :council_members
    resources :tags, only: [ :index, :update, :destroy ] do
      get :search, on: :collection
      post :seed_rules, on: :collection
    end
    resources :tag_rules, only: [ :create, :destroy ]
    resources :agenda_items, only: [ :update, :destroy ] do
      get :untagged, on: :collection
      post :auto_tag_all, on: :collection
    end
    resources :agenda_item_tags, only: [ :create, :destroy ] do
      post :copy, on: :collection
    end
    resources :blog_posts do
      post :publish, on: :member
    end
    resources :email_campaigns do
      post :send_campaign, on: :member
      get :preview, on: :member
    end
  end

  get "dashboard", to: "dashboard#show", as: :dashboard
  resources :stars, only: [ :index, :create, :destroy ]

  resources :meetings, only: [ :index, :show ]
  resources :council_members, only: [ :index, :show ]
  resources :tags, only: [ :index, :show ], path: "topics"
  resources :blog_posts, only: [ :index, :show ], path: "blog"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "search", to: "search#index", as: :search

  get "email-preferences", to: "unsubscribes#show", as: :unsubscribe
  patch "email-preferences", to: "unsubscribes#update"
  post "email-preferences/unsubscribe-all", to: "unsubscribes#unsubscribe_all", as: :unsubscribe_all

  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy

  root "pages#home"
end
