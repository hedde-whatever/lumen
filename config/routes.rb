Rails.application.routes.draw do
  if defined?(Rswag::Api)
    mount Rswag::Api::Engine => "/api-docs"
    mount Rswag::Ui::Engine  => "/api-docs"
  end
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "auth/me", to: "auth#me"

      resources :events, only: [ :index, :show, :create, :update, :destroy ] do
        resources :media, only: [ :index, :create, :destroy ]
      end
    end
  end
end
