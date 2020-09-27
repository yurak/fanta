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

    resources :links, except: [:show]
  end

  resources :matches, only: [:show]

  resources :match_players, only: [:update]

  resources :players, only: [:index, :show] do
    get :change_status
  end

  resources :tours, only: [:show, :edit, :update] do
    get :change_status
    get :inject_scores
  end

  resources :teams, only: [:show] do
    resources :lineups, except: [:index, :show, :destroy] do
      collection { get :clone }
      get :edit_module
      get :edit_scores
      get :substitutions
      put :subs_update
    end
  end

  resources :tournament_rounds, only: [:show, :edit, :update] do
    get :edit_scores
    put :update_scores

    resources :round_players, only: [:index]
  end

  resources :users, only: [:show, :edit, :update] do
    get :edit_avatar
  end

  namespace :api do
    get :table, to: 'results#index'
    get :fixtures, to: 'matches#fixtures'
    get :results, to: 'matches#results'
  end
end
