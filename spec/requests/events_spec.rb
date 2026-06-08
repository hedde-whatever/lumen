require "rails_helper"

RSpec.describe "Events", type: :request do
  let!(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/events" do
    before { create_list(:event, 3, user: user) }

    it "returns the user's events" do
      get "/api/v1/events", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_response.length).to eq(3)
    end

    it "does not return other users' events" do
      create(:event)
      get "/api/v1/events", headers: headers
      expect(json_response.length).to eq(3)
    end

    it "returns 401 without a token" do
      get "/api/v1/events"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/events/:id" do
    let!(:event) { create(:event, user: user) }

    it "returns the event" do
      get "/api/v1/events/#{event.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(event.id)
      expect(json_response["name"]).to eq(event.name)
    end

    it "returns 404 for another user's event" do
      other_event = create(:event)
      get "/api/v1/events/#{other_event.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without a token" do
      get "/api/v1/events/#{event.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/events" do
    let(:valid_params) do
      { name: "Radiohead at Roskilde", date: "2026-07-04",
        city: "Roskilde", country_name: "Denmark", country_code: "DK",
        full_address: "Roskilde Festival, Denmark", address: "Roskilde Festival",
        feature_type: "venue", lat: 55.6470, lng: 12.0827 }
    end

    it "creates an event" do
      post "/api/v1/events", params: valid_params, headers: headers
      expect(response).to have_http_status(:created)
      expect(json_response["name"]).to eq("Radiohead at Roskilde")
    end

    it "returns errors for a missing name" do
      post "/api/v1/events", params: valid_params.merge(name: ""), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["errors"]).to be_present
    end

    it "returns 401 without a token" do
      post "/api/v1/events", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/events/:id" do
    let!(:event) { create(:event, user: user) }

    it "updates the event" do
      patch "/api/v1/events/#{event.id}", params: { name: "Updated" }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_response["name"]).to eq("Updated")
    end

    it "returns 404 for another user's event" do
      other_event = create(:event)
      patch "/api/v1/events/#{other_event.id}", params: { name: "Hacked" }, headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without a token" do
      patch "/api/v1/events/#{event.id}", params: { name: "Updated" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/events/:id" do
    let!(:event) { create(:event, user: user) }

    it "deletes the event" do
      delete "/api/v1/events/#{event.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Event.find_by(id: event.id)).to be_nil
    end

    it "returns 404 for another user's event" do
      other_event = create(:event)
      delete "/api/v1/events/#{other_event.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without a token" do
      delete "/api/v1/events/#{event.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
