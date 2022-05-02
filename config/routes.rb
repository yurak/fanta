Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users

  root to: 'welcome#index'

  resource :welcome, only: [:index]
  get 'about',    to: 'welcome#about'
  get 'contact',  to: 'welcome#contact'
  get 'guide',    to: 'welcome#guide'
  get 'rules',    to: 'welcome#rules'

  resources :articles

  resources :auction_rounds, only: [:show] do
    resources :auction_bids, only: [:new, :create, :edit, :update]
  end

  resources :join_requests, only: [:new, :create]
  get :success_request, to: 'join_requests#success_request'

  resources :leagues, only: [:index, :show] do
    resources :auctions, only: [:index, :show, :update] do
      resources :transfers, only: [:index, :create, :destroy]
    end

    resources :results, only: [:index]
  end

  resources :links, only: [:index]

  resources :matches, only: [:show]

  resources :national_teams, only: [:show]

  resources :players, only: [:index, :show, :update] do
    resources :player_requests, only: [:new, :create]
  end

  resources :match_players, only: [] do
    resources :substitutes, only: [:new, :create, :destroy]
  end

  resources :teams, only: [:show, :edit, :update] do
    resources :lineups, only: [:show, :new, :create, :edit, :update] do
      collection { get :clone }
    end
  end

  resources :tournaments, only: [:show]

  resources :tours, only: [:show, :update] do
    get :inject_scores, on: :member
  end

  resources :tournament_rounds, only: [:edit, :update] do
    resources :round_players, only: [:index]
  end

  resources :users, only: [:show, :edit, :update] do
    get :edit_avatar, on: :member
  end
end
