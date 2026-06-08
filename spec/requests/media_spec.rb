require "rails_helper"

RSpec.describe "Media", type: :request do
  let!(:user)    { create(:user) }
  let!(:event)   { create(:event, user: user) }
  let(:headers)  { auth_headers(user) }
  let(:base_url) { "/api/v1/events/#{event.id}/media" }

  describe "GET /api/v1/events/:event_id/media" do
    before { create_list(:medium, 2, user: user, event: event) }

    it "returns the event's media" do
      get base_url, headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_response["items"].length).to eq(2)
      expect(json_response["items"].first).to include("url")
    end
  end

  describe "POST /api/v1/events/:event_id/media" do
    let(:file) do
      fixture_file_upload(
        Rails.root.join("spec/fixtures/files/photo.jpg"),
        "image/jpeg"
      )
    end

    it "uploads a file and creates a media record" do
      post base_url, params: { file: file }, headers: headers
      expect(response).to have_http_status(:created)
      expect(json_response).to include("url")
    end
  end

  describe "DELETE /api/v1/events/:event_id/media/:id" do
    let!(:medium) { create(:medium, user: user, event: event) }

    it "deletes the media record" do
      delete "#{base_url}/#{medium.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Medium.find_by(id: medium.id)).to be_nil
    end
  end
end
