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

  resources :join_requests, only: [:new, :create]
  get :success_request, to: 'join_requests#success_request'

  resources :leagues, only: [:index] do
    resources :results, only: [:index]
    resources :transfers, only: [:index, :create]
    get :auction, to: 'transfers#auction'
  end

  resources :links, only: [:index]

  resources :matches, only: [:show]

  resources :national_teams, only: [:show]

  resources :players, only: [:index, :show]

  resources :teams, only: [:show] do
    resources :lineups, only: [:show, :new, :create, :edit, :update] do
      collection { get :clone }
      get :substitutions, on: :member
      put :subs_update, on: :member
    end
  end

  resources :tournaments, only: [:show]

  resources :tours, only: [:show, :edit, :update] do
    get :change_status, on: :member
    get :inject_scores, on: :member
  end

  resources :tournament_rounds, only: [:edit, :update] do
    resources :round_players, only: [:index]
  end

  resources :users, only: [:show, :edit, :update] do
    get :edit_avatar, on: :member
  end
end
