require "rails_helper"

RSpec.describe "SSO", type: :request do
  # Shared RSA key pair used to sign fake id_tokens in tests
  let(:rsa_key)   { OpenSSL::PKey::RSA.generate(2048) }
  let(:jwk)       { JWT::JWK.new(rsa_key) }
  let(:jwks_hash) { { "keys" => [ jwk.export(include_private: false) ] } }

  def build_id_token(payload, key: rsa_key)
    JWT.encode(payload, key, "RS256", kid: jwk.kid)
  end

  before do
    allow(Rails.cache).to receive(:fetch).and_yield
    allow(Net::HTTP).to receive(:get).and_return(jwks_hash.to_json)
    stub_const("ENV", ENV.to_h.merge("GOOGLE_CLIENT_ID" => "google-client-id"))
  end

  describe "POST /api/v1/auth/sso/google" do
    let(:payload) do
      {
        "sub"   => "google-uid-123",
        "email" => "alice@example.com",
        "name"  => "Alice Smith",
        "iss"   => "https://accounts.google.com",
        "aud"   => "google-client-id",
        "exp"   => 1.hour.from_now.to_i,
        "iat"   => Time.now.to_i
      }
    end

    it "creates a new user and returns tokens" do
      post "/api/v1/auth/sso/google", params: { id_token: build_id_token(payload) }

      expect(response).to have_http_status(:ok)
      expect(json_response).to include("access_token", "refresh_token", "user")
      expect(json_response["user"]["email"]).to eq("alice@example.com")
      expect(User.find_by(email: "alice@example.com")).to be_present
    end

    it "links an existing password user to Google SSO" do
      existing = create(:user, email: "alice@example.com")

      post "/api/v1/auth/sso/google", params: { id_token: build_id_token(payload) }

      expect(response).to have_http_status(:ok)
      expect(User.count).to eq(1)
      expect(existing.provider_identities.reload.count).to eq(1)
    end

    it "returns the same user on subsequent logins" do
      post "/api/v1/auth/sso/google", params: { id_token: build_id_token(payload) }
      post "/api/v1/auth/sso/google", params: { id_token: build_id_token(payload) }

      expect(User.count).to eq(1)
      expect(response).to have_http_status(:ok)
    end

    it "returns 422 for an invalid id_token" do
      post "/api/v1/auth/sso/google", params: { id_token: "not.a.token" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to have_key("error")
    end
  end
end
