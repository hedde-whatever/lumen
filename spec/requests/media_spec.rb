require "rails_helper"

RSpec.describe "Media", type: :request do
  let!(:user)    { create(:user) }
  let!(:event)   { create(:event, user: user) }
  let(:headers)  { auth_headers(user) }
  let(:base_url) { "/api/v1/events/#{event.id}/media" }
  let(:jpeg) { fixture_file_upload(Rails.root.join("spec/fixtures/files/photo.jpg"), "image/jpeg") }

  describe "GET /api/v1/events/:event_id/media" do
    before { create_list(:medium, 2, user: user, event: event) }

    it "returns the event's media" do
      get base_url, headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_response["items"].length).to eq(2)
      expect(json_response["items"].first).to include("url", "thumbnail_url")
      expect(json_response["limit"]).to eq(10)
      expect(json_response["remaining"]).to eq(8)
    end

    it "returns 404 for another user's event" do
      other_event = create(:event)
      get "/api/v1/events/#{other_event.id}/media", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without a token" do
      get base_url
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/events/:event_id/media" do
    it "uploads a JPEG and returns url and thumbnail_url" do
      post base_url, params: { file: jpeg }, headers: headers
      expect(response).to have_http_status(:created)
      expect(json_response).to include("url", "thumbnail_url")
      expect(json_response["url"]).to be_present
    end

    it "returns 422 when the file exceeds 10 MB" do
      oversized = fixture_file_upload(Rails.root.join("spec/fixtures/files/photo.jpg"), "image/jpeg")
      allow(oversized).to receive(:size).and_return(11.megabytes)
      # Stub the blob size check at the model level
      allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(11.megabytes)
      post base_url, params: { file: oversized }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["errors"].first).to include("10 MB")
    end

    it "returns 422 for a non-image file" do
      pdf = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/document.pdf"),
        "application/pdf"
      )
      post base_url, params: { file: pdf }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["errors"].first).to include("JPEG, PNG, WebP, or GIF")
    end

    it "returns 422 when the photo limit is reached" do
      create_list(:medium, 10, user: user, event: event)
      post base_url, params: { file: jpeg }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["error"]).to include("limit")
    end

    it "returns 404 for another user's event" do
      other_event = create(:event)
      post "/api/v1/events/#{other_event.id}/media", params: { file: jpeg }, headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without a token" do
      post base_url, params: { file: jpeg }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/events/:event_id/media/:id" do
    let!(:medium) { create(:medium, user: user, event: event) }

    it "deletes the media record" do
      delete "#{base_url}/#{medium.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Medium.find_by(id: medium.id)).to be_nil
    end

    it "returns 404 for another user's media" do
      other_medium = create(:medium)
      delete "/api/v1/events/#{other_medium.event_id}/media/#{other_medium.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without a token" do
      delete "#{base_url}/#{medium.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
