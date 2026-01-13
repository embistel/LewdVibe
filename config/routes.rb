Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root 'movies#index'
  
  resources :movies, only: [:index, :show] do
    member do
      get :poster
      get :download_subtitle
      get :storyboard_image
      get :subtitles_data
    end
  end
  resources :registrations, only: [:new, :create]
  resources :actors, only: [:index, :show]
  resources :studios, only: [:index, :show]
  resources :directors, only: [:index, :show]

  resource :profile, only: [:show, :edit, :update, :destroy]
  
  namespace :admin do
    root to: "dashboards#show"
    resources :users, only: [:index, :destroy]
    resources :sources, only: [:index, :create, :destroy] do
      post :sync, on: :collection
    end
  end
end
