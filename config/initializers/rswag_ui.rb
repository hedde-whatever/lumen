return unless defined?(Rswag::Ui)

Rswag::Ui.configure do |c|
  c.openapi_endpoint "/api-docs/v1/swagger.yaml", "Lumen API V1"
end
