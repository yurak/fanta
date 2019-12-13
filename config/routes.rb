Rails.application.routes.draw do
  devise_for :users

  resources :tours do
    get :change_status
    get :edit_subs_scores
    get :inject_scores
    put :update_subs_scores
  end

  resources :teams do
    resources :players, only: [:show] do
      get :change_status
    end

    resources :lineups do
      get :clone
      get :details
      get :edit_module
      get :edit_scores
      get :substitutions
      put :subs_update
    end
  end

  resources :results, only: [:index]

  resources :clubs, only: [:index]

  resource :welcome, only: [:index]
  get 'rules', to: 'welcome#rules'

  resources :links, except: [:show]

  resources :articles

  root to: "welcome#index"

  namespace :api do
    get :table, to: 'results#index'
    get :fixtures, to: 'matches#fixtures'
    get :results, to: 'matches#results'
  end
end
