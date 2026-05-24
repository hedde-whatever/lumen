require "swagger_helper"

RSpec.describe "Events", type: :request do
  let!(:user)         { create(:user) }
  let(:Authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }

  path "/api/v1/events" do
    get "List events" do
      tags     "Events"
      produces "application/json"
      security [bearer: []]

      parameter name: :page,     in: :query, type: :integer, required: false, description: "Page number (default: 1)"
      parameter name: :per_page, in: :query, type: :integer, required: false, description: "Records per page (default: 20)"

      response "200", "events listed" do
        schema type: :array, items: { "$ref" => "#/components/schemas/Event" }
        before { create_list(:event, 2, user: user) }
        run_test!
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/Error"
        let(:Authorization) { nil }
        run_test!
      end
    end

    post "Create an event" do
      tags     "Events"
      consumes "application/json"
      produces "application/json"
      security [bearer: []]

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:name],
        properties: {
          name:         { type: :string,  example: "Radiohead at Roskilde" },
          date:         { type: :string,  format: :date, example: "2026-07-04" },
          country_name: { type: :string,  example: "Denmark" },
          country_code: { type: :string,  example: "DK" },
          region_name:  { type: :string,  example: "Zealand" },
          city:         { type: :string,  example: "Roskilde" },
          full_address: { type: :string,  example: "Roskilde Festival, Denmark" },
          address:      { type: :string,  example: "Roskilde Festival" },
          feature_type: { type: :string,  example: "venue" },
          lat:          { type: :number,  example: 55.6470 },
          lng:          { type: :number,  example: 12.0827 },
          note:         { type: :string,  example: "Amazing show, front row!" }
        }
      }

      response "201", "event created" do
        schema "$ref" => "#/components/schemas/Event"
        let(:body) { { name: "Radiohead at Roskilde", date: "2026-07-04", city: "Roskilde",
                       country_name: "Denmark", country_code: "DK", full_address: "Roskilde Festival",
                       address: "Roskilde Festival", feature_type: "venue", lat: 55.6470, lng: 12.0827 } }
        run_test!
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/Error"
        let(:Authorization) { nil }
        let(:body) { { name: "Test" } }
        run_test!
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/Errors"
        let(:body) { { name: "" } }
        run_test!
      end
    end
  end

  path "/api/v1/events/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true

    get "Get an event" do
      tags     "Events"
      produces "application/json"
      security [bearer: []]

      response "200", "event found" do
        schema "$ref" => "#/components/schemas/Event"
        let!(:event) { create(:event, user: user) }
        let(:id)     { event.id }
        run_test!
      end

      response "404", "not found" do
        schema "$ref" => "#/components/schemas/Error"
        let(:id) { 0 }
        run_test!
      end
    end

    patch "Update an event" do
      tags     "Events"
      consumes "application/json"
      produces "application/json"
      security [bearer: []]

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          name:  { type: :string },
          date:  { type: :string, format: :date },
          note:  { type: :string },
          city:  { type: :string },
          lat:   { type: :number },
          lng:   { type: :number }
        }
      }

      response "200", "event updated" do
        schema "$ref" => "#/components/schemas/Event"
        let!(:event) { create(:event, user: user) }
        let(:id)     { event.id }
        let(:body)   { { name: "Updated Name" } }
        run_test!
      end

      response "404", "not found" do
        schema "$ref" => "#/components/schemas/Error"
        let(:id)   { 0 }
        let(:body) { { name: "x" } }
        run_test!
      end
    end

    delete "Delete an event" do
      tags     "Events"
      security [bearer: []]

      response "204", "event deleted" do
        let!(:event) { create(:event, user: user) }
        let(:id)     { event.id }
        run_test!
      end

      response "404", "not found" do
        schema "$ref" => "#/components/schemas/Error"
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
