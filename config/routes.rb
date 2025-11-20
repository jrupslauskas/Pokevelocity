Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Homepage with login form
  root "sessions#new"

  # Session routes (login/logout)
  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  # Trainer registration
  get "/trainers/new", to: "trainers#new", as: :new_trainer
  post "/trainers", to: "trainers#create", as: :trainers

  # Dashboard
  get "/dashboard", to: "trainers#dashboard", as: :dashboard

  # Pokedex
  get "/pokedex", to: "trainers#pokedex", as: :pokedex

  # Leaderboard
  get "/leaderboard", to: "leaderboard#index", as: :leaderboard

  # Redeem rewards
  get "/rewards", to: "rewards#index", as: :rewards
  post "/rewards", to: "rewards#create"

  # Catch Pokemon
  get "/catch", to: "catches#new", as: :catches
  get "/catch/:id", to: "catches#show", as: :catch
  post "/catch/:id", to: "catches#create"
end
