require "swagger_helper"

RSpec.describe "Media", type: :request do
  let!(:user)         { create(:user) }
  let!(:event)        { create(:event, user: user) }
  let(:Authorization) { "Bearer fake-clerk-token" }
  before { clerk_auth(user) if send(:Authorization).present? }

  path "/api/v1/events/{event_id}/media" do
    parameter name: :event_id, in: :path, type: :integer, required: true

    get "List media for an event" do
      tags     "Media"
      produces "application/json"
      security [ bearer: [] ]

      response "200", "media listed" do
        schema type: :object,
               required: [ "items", "limit", "remaining" ],
               properties: {
                 items:     { type: :array, items: { "$ref" => "#/components/schemas/Medium" } },
                 limit:     { type: :integer, example: 10 },
                 remaining: { type: :integer, example: 8 }
               }
        before { create_list(:medium, 2, user: user, event: event) }
        let(:event_id) { event.id }
        run_test!
      end

      response "404", "event not found" do
        schema "$ref" => "#/components/schemas/Error"
        let(:event_id) { 0 }
        run_test!
      end
    end

    post "Upload media to an event" do
      tags     "Media"
      consumes "multipart/form-data"
      produces "application/json"
      security [ bearer: [] ]

      parameter name: :file, in: :formData, type: :file, required: true,
                description: "Image or video file to upload"

      response "201", "media uploaded" do
        schema "$ref" => "#/components/schemas/Medium"
        let(:event_id) { event.id }
        let(:file) do
          fixture_file_upload(
            Rails.root.join("spec/fixtures/files/photo.jpg"),
            "image/jpeg"
          )
        end
        run_test!
      end

      response "404", "event not found" do
        schema "$ref" => "#/components/schemas/Error"
        let(:event_id) { 0 }
        let(:file) do
          fixture_file_upload(
            Rails.root.join("spec/fixtures/files/photo.jpg"),
            "image/jpeg"
          )
        end
        run_test!
      end

      response "422", "photo limit reached" do
        schema "$ref" => "#/components/schemas/Error"
        before { create_list(:medium, 10, user: user, event: event) }
        let(:event_id) { event.id }
        let(:file) do
          fixture_file_upload(
            Rails.root.join("spec/fixtures/files/photo.jpg"),
            "image/jpeg"
          )
        end
        run_test!
      end
    end
  end

  path "/api/v1/events/{event_id}/media/{id}" do
    parameter name: :event_id, in: :path, type: :integer, required: true
    parameter name: :id,       in: :path, type: :integer, required: true

    delete "Delete a media record" do
      tags     "Media"
      security [ bearer: [] ]

      response "204", "media deleted" do
        let!(:medium)  { create(:medium, user: user, event: event) }
        let(:event_id) { event.id }
        let(:id)       { medium.id }
        run_test!
      end

      response "404", "not found" do
        schema "$ref" => "#/components/schemas/Error"
        let(:event_id) { event.id }
        let(:id)       { 0 }
        run_test!
      end
    end
  end
end
