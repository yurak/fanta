Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get 'hello_world', to: 'hello_world#index'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    registrations: 'users/registrations'
  }

  root to: 'welcome#index'

  devise_scope :user do
    get "users/confirmations", to: "users/confirmations#index"
    get "users/passwords"    , to: "users/passwords#index"
  end

  resource :welcome, only: [:index]
  get 'about',    to: 'welcome#about'
  get 'contact',  to: 'welcome#contact'
  get 'fees',     to: 'welcome#fees'
  get 'guide',    to: 'welcome#guide'
  get 'rules',    to: 'welcome#rules'

  telegram_webhook Telegram::WebhookController
  # telegram_webhook Telegram::WebhookController, :mantra_prod

  resources :articles

  resources :auction_rounds, only: [:show] do
    resources :auction_bids, only: [:update]
  end

  resources :join_requests, only: [:new, :create, :index]

  resources :leagues, only: [:index, :show] do
    resources :auctions, only: [:index, :show, :update] do
      resources :transfers, only: [:index, :create, :destroy]
    end

    resources :results, only: [:index]
  end

  resources :links, only: [:index]

  resources :matches, only: [:show] do
    post :autobot
  end

  resources :national_teams, only: [:show]

  resources :players, only: [:index, :show, :update] do
    resources :player_requests, only: [:new, :create]
  end

  resources :player_bids, only: [:update]

  resources :match_players, only: [] do
    resources :substitutes, only: [:new, :create, :destroy]
  end

  resources :slots, only: [:index]

  resources :teams, only: [:show, :edit, :update, :new, :create] do
    resources :lineups, only: [:show, :new, :create, :edit, :update] do
      collection { get :clone }
    end

    resources :player_teams, only: [:edit, :update]
  end

  resources :tournaments, only: [:show] do
    resources :clubs, only: [:show]
    resources :divisions, only: [:index]
  end

  resources :tours, only: [:show, :update] do
    get :inject_scores, on: :member
    get :preview, on: :member
  end

  resources :tournament_rounds, only: [:show, :edit, :update] do
    put :auto_close, on: :member
    put :tours_update, on: :member

    get :auto_subs
    get :generate_preview
    get :auto_subs_preview
    resources :round_players, only: [:index]
  end

  resources :users, only: [:show, :edit, :update] do
    get :edit_avatar, on: :member
    get :new_avatar, on: :member
    get :new_name, on: :member
    put :new_update, on: :member
  end

  namespace :api do
    resources :leagues, only: [:index, :show] do
      resources :results, only: [:index]
    end
    resources :players, only: [:index, :show] do
      get :stats, on: :member
    end
    resources :seasons, only: [:index]
    resources :teams, only: [:show]
    resources :tournaments, only: [:index] do
      resources :divisions, only: [:index]
    end
  end
end
