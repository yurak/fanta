Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users

  root to: "welcome#index"

  resource :welcome, only: [:index]
  get 'rules', to: 'welcome#rules'

  resources :leagues, only: [:index] do
    get :tours, to: 'tours#index'

    resources :results, only: [:index]

    resources :links, except: [:show]
  end

  resources :tours, only: [:show, :edit, :update] do
    get :change_status
    get :inject_scores
  end

  resources :tournament_rounds, only: [:show, :edit, :update] do
    get :edit_scores
    put :update_scores

    resources :round_players, only: [:index]
  end

  resources :teams, only: [:show] do
    resources :lineups, except: [:destroy] do
      collection { get :clone }
      get :details
      get :edit_module
      get :edit_scores
      get :substitutions
      put :subs_update
    end
  end

  resources :players, only: [:show] do
    get :change_status
  end

  resources :articles

  namespace :api do
    get :table, to: 'results#index'
    get :fixtures, to: 'matches#fixtures'
    get :results, to: 'matches#results'
  end
end
