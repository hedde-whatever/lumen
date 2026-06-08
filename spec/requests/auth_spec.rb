require "rails_helper"

RSpec.describe "Auth", type: :request do
  describe "GET /api/v1/auth/me" do
    let!(:user) { create(:user) }

    it "returns the current user" do
      get "/api/v1/auth/me", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_response["user"]["id"]).to eq(user.id)
      expect(json_response["user"]["email"]).to eq(user.email)
    end

    it "returns 401 without a token" do
      get "/api/v1/auth/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
