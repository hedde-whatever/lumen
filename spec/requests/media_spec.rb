require "rails_helper"

RSpec.describe "Media", type: :request do
  let!(:user)    { create(:user) }
  let!(:event)   { create(:event, user: user) }
  let(:headers)  { auth_headers(user) }
  let(:base_url) { "/api/v1/events/#{event.id}/media" }

  describe "GET /api/v1/events/:event_id/media" do
    before { create_list(:medium, 2, user: user, event: event) }

    it "returns the event's media with presigned URLs" do
      allow(S3Client).to receive(:presigned_url).and_return("http://localhost:4566/bucket/key")
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

    before do
      allow(S3UploadService).to receive(:upload).and_return("uploads/users/1/events/1/uuid-photo.jpg")
      allow(S3Client).to receive(:presigned_url).and_return("http://localhost:4566/bucket/key")
    end

    it "uploads a file and creates a media record" do
      post base_url, params: { file: file }, headers: headers
      expect(response).to have_http_status(:created)
      expect(json_response).to include("path", "url")
    end
  end

  describe "DELETE /api/v1/events/:event_id/media/:id" do
    let!(:medium) { create(:medium, user: user, event: event) }

    before { allow(S3UploadService).to receive(:delete) }

    it "deletes the media record" do
      delete "#{base_url}/#{medium.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Medium.find_by(id: medium.id)).to be_nil
    end
  end
end
