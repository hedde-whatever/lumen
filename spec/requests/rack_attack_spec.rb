require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  let!(:user)  { create(:user) }
  let!(:event) { create(:event, user: user) }

  around do |example|
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
    example.run
  ensure
    Rack::Attack.enabled = false
  end

  before do
    # Inject a fake clerk proxy into the Rack env so throttles can read
    # a user_id at the Rack level (Clerk middleware is removed in test).
    clerk_double = double("ClerkProxy", user_id: user.clerk_id, user: double(
      id: user.clerk_id, first_name: user.name, last_name: nil,
      email_addresses: [ double(email_address: user.email) ]
    ))
    allow_any_instance_of(ActionDispatch::Request).to \
      receive(:env).and_wrap_original { |m| m.call.merge("clerk" => clerk_double) }
  end

  describe "upload throttle" do
    let(:headers) { auth_headers(user) }
    let(:jpeg)    { fixture_file_upload(Rails.root.join("spec/fixtures/files/photo.jpg"), "image/jpeg") }

    it "returns 429 after 20 uploads within a minute" do
      20.times { post "/api/v1/events/#{event.id}/media", params: { file: jpeg }, headers: headers }
      post "/api/v1/events/#{event.id}/media", params: { file: jpeg }, headers: headers

      expect(response).to have_http_status(429)
      expect(json_response["error"]).to include("Too many requests")
      expect(response.headers["Retry-After"]).to be_present
    end
  end

  describe "general API throttle" do
    let(:headers) { auth_headers(user) }

    it "returns 429 after 300 requests in 5 minutes" do
      300.times { get "/api/v1/events", headers: headers }
      get "/api/v1/events", headers: headers

      expect(response).to have_http_status(429)
      expect(json_response["error"]).to include("Too many requests")
    end
  end
end
