require "rails_helper"

RSpec.describe "Auth", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_params) do
      { name: "Alice", email: "alice@example.com", password: "secret123", password_confirmation: "secret123" }
    end

    it "creates a user and returns a token" do
      post "/api/v1/auth/register", params: valid_params
      expect(response).to have_http_status(:created)
      expect(json_response).to include("token", "user")
      expect(json_response["user"]["email"]).to eq("alice@example.com")
    end

    it "returns errors for invalid data" do
      post "/api/v1/auth/register", params: { name: "", email: "bad", password: "x" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["errors"]).to be_present
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "bob@example.com", password: "mypassword") }

    it "returns a token for valid credentials" do
      post "/api/v1/auth/login", params: { email: "bob@example.com", password: "mypassword" }
      expect(response).to have_http_status(:ok)
      expect(json_response).to include("token")
    end

    it "returns 401 for wrong password" do
      post "/api/v1/auth/login", params: { email: "bob@example.com", password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    let!(:user) { create(:user) }

    it "returns the current user" do
      get "/api/v1/auth/me", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_response["user"]["id"]).to eq(user.id)
    end

    it "returns 401 without a token" do
      get "/api/v1/auth/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
