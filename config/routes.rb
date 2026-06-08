Rails.application.routes.draw do
  mount Rswag::Api::Engine => "/api-docs"
  mount Rswag::Ui::Engine => "/api-docs"
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/sso/google", to: "sso#google"

      post   "auth/register", to: "auth#register"
      post   "auth/login",    to: "auth#login"
      get    "auth/me",       to: "auth#me"
      post   "auth/refresh",  to: "auth#refresh"
      delete "auth/logout",   to: "auth#logout"

      resources :events, only: [ :index, :show, :create, :update, :destroy ] do
        resources :media, only: [ :index, :create, :destroy ]
      end
    end
  end
end
