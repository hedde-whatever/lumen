require "swagger_helper"

RSpec.describe "Auth", type: :request do
  path "/api/v1/auth/register" do
    post "Register a new user" do
      tags        "Auth"
      consumes    "application/json"
      produces    "application/json"

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:name, :email, :password, :password_confirmation],
        properties: {
          name:                  { type: :string, example: "Oliver" },
          email:                 { type: :string, format: :email, example: "oliver@example.com" },
          password:              { type: :string, format: :password, example: "secret123" },
          password_confirmation: { type: :string, format: :password, example: "secret123" }
        }
      }

      response "201", "user created" do
        schema type: :object, properties: {
          token: { type: :string },
          user:  { "$ref" => "#/components/schemas/User" }
        }
        let(:body) { { name: "Oliver", email: "oliver@example.com", password: "secret123", password_confirmation: "secret123" } }
        run_test!
      end

      response "422", "validation failed" do
        schema "$ref" => "#/components/schemas/Errors"
        let(:body) { { name: "", email: "bad", password: "x", password_confirmation: "y" } }
        run_test!
      end
    end
  end

  path "/api/v1/auth/login" do
    post "Log in" do
      tags     "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        required: [:email, :password],
        properties: {
          email:    { type: :string, format: :email, example: "oliver@example.com" },
          password: { type: :string, format: :password, example: "secret123" }
        }
      }

      response "200", "login successful" do
        schema type: :object, properties: {
          token: { type: :string },
          user:  { "$ref" => "#/components/schemas/User" }
        }
        let!(:user) { create(:user, email: "oliver@example.com", password: "secret123") }
        let(:body)  { { email: "oliver@example.com", password: "secret123" } }
        run_test!
      end

      response "401", "invalid credentials" do
        schema "$ref" => "#/components/schemas/Error"
        let!(:user) { create(:user, email: "oliver@example.com", password: "secret123") }
        let(:body)  { { email: "oliver@example.com", password: "wrong" } }
        run_test!
      end
    end
  end

  path "/api/v1/auth/me" do
    get "Get current user" do
      tags     "Auth"
      produces "application/json"
      security [bearer: []]

      response "200", "current user" do
        schema type: :object, properties: {
          user: { "$ref" => "#/components/schemas/User" }
        }
        let!(:user)          { create(:user) }
        let(:Authorization)  { "Bearer #{JwtService.encode(user_id: user.id)}" }
        run_test!
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/Error"
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
