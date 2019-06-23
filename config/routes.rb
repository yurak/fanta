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

  root to: "teams#index"
end
