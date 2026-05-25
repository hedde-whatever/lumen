Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.development?
      # Match any localhost origin (any port) so Swagger UI and local frontends work regardless of port
      origins(/\Ahttp:\/\/localhost(:\d+)?\z/)
    else
      origins ENV.fetch("ALLOWED_ORIGINS", "").split(",").map(&:strip)
    end

    resource "*",
      headers:     :any,
      methods:     [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose:      [ "Authorization" ],
      credentials: true
  end
end
