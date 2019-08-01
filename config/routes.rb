Rails.application.routes.draw do
  resources :tours do
    get :change_status
  end

  resources :teams do
    resources :players, only: [:show] do
      get :change_status
    end

    resources :lineups do
      get :clone
    end
  end

  resource :welcome, only: [:index]
  get 'rules', to: 'welcome#rules'

  resources :links, except: [:show]

  root to: "welcome#index"
end
