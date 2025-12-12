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
  post "/dashboard", to: redirect("/dashboard")  # Handle accidental POST requests

  # Pokedex
  get "/pokedex", to: "trainers#pokedex", as: :pokedex

  # Evolution Lab
  get "/evolution-lab", to: "trainers#evolution_lab", as: :evolution_lab
  post "/evolution-lab/evolve/:id", to: "trainers#evolve", as: :evolve

  # Leaderboard
  get "/leaderboard", to: "leaderboard#index", as: :leaderboard

  # Trainer Plaza
  get "/trainer-plaza", to: "trainer_plaza#index", as: :trainer_plaza
  post "/trainer-plaza", to: redirect("/trainer-plaza")  # Handle accidental POST requests
  get "/trainer-plaza/:id", to: "trainer_plaza#show", as: :trainer

  # Redeem rewards
  get "/rewards", to: "rewards#index", as: :rewards
  post "/rewards", to: "rewards#create"
  post "/rewards/buy", to: "rewards#buy_item", as: :buy_item_rewards
  post "/rewards/sell", to: "rewards#sell_item", as: :sell_item_rewards

  # Catch Pokemon
  get "/catch", to: "catches#new", as: :catches
  post "/catch/adventure/:id", to: "catches#adventure", as: :adventure
  get "/catch/:id", to: "catches#show", as: :catch
  post "/catch/:id", to: "catches#create"
  post "/catch/:id/run", to: "catches#run", as: :run_from_catch
end
