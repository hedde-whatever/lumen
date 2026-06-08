require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title:       "Lumen API",
        version:     "v1",
        description: "Concert-logging API — Strava for music"
      },
      servers: [
        { url: "/", description: "Local dev" }
      ],
      components: {
        securitySchemes: {
          bearer: {
            type:         :http,
            scheme:       :bearer,
            bearerFormat: "JWT",
            description:  "Obtain a token from POST /api/v1/auth/login"
          }
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              id:         { type: :integer },
              name:       { type: :string },
              email:      { type: :string, format: :email },
              created_at: { type: :string, format: :"date-time" }
            }
          },
          Event: {
            type: :object,
            properties: {
              id:           { type: :integer },
              name:         { type: :string },
              date:         { type: :string, format: :date, nullable: true },
              country_name: { type: :string, nullable: true },
              country_code: { type: :string, nullable: true },
              region_name:  { type: :string, nullable: true },
              city:         { type: :string, nullable: true },
              full_address: { type: :string, nullable: true },
              address:      { type: :string, nullable: true },
              feature_type: { type: :string, nullable: true },
              lat:          { type: :number, nullable: true },
              lng:          { type: :number, nullable: true },
              note:         { type: :string, nullable: true },
              created_at:   { type: :string, format: :"date-time" },
              updated_at:   { type: :string, format: :"date-time" }
            }
          },
          Medium: {
            type: :object,
            properties: {
              id:         { type: :integer },
              path:       { type: :string, description: "S3 object key" },
              url:        { type: :string, description: "Presigned S3 URL (expires in 6 days)" },
              created_at: { type: :string, format: :"date-time" }
            }
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string }
            }
          },
          Errors: {
            type: :object,
            properties: {
              errors: { type: :array, items: { type: :string } }
            }
          },
          AuthResponse: {
            type: :object,
            properties: {
              access_token:  { type: :string },
              refresh_token: { type: :string },
              user:          { "$ref" => "#/components/schemas/User" }
            }
          }
        }
      },
      paths: {}
    }
  }

  config.openapi_format = :yaml
end
