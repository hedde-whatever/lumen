# Disabled in test — enabled per-spec via Rack::Attack.enabled = true
Rack::Attack.enabled = false if Rails.env.test?

class Rack::Attack
  # General API throttle — per authenticated Clerk user
  throttle("api/user", limit: 300, period: 5.minutes) do |req|
    req.env["clerk"]&.user_id if req.path.start_with?("/api/")
  end

  # Media uploads — per authenticated user (protects R2 storage costs)
  throttle("api/uploads", limit: 20, period: 1.minute) do |req|
    req.env["clerk"]&.user_id if req.path.match?(%r{/api/.*/media}) && req.post?
  end

  # IP fallback — covers unauthenticated requests and general abuse
  throttle("req/ip", limit: 100, period: 1.minute) do |req|
    req.ip unless req.path == "/up"
  end

  # Block oversized upload requests before they consume memory (10 MB limit)
  blocklist("block/large_uploads") do |req|
    req.path.match?(%r{/api/.*/media}) && req.post? &&
      req.content_length.to_i > 10.megabytes
  end

  # Return JSON 413 for blocked oversized uploads
  self.blocklisted_responder = lambda do |req|
    [
      413,
      { "Content-Type" => "application/json" },
      [ { error: "File too large. Maximum upload size is 10 MB." }.to_json ]
    ]
  end

  # Return JSON 429 instead of the default plain-text response
  self.throttled_responder = lambda do |req|
    match_data  = req.env["rack.attack.match_data"]
    retry_after = match_data ? (match_data[:period] - (Time.now.to_i % match_data[:period])) : 60
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [ { error: "Too many requests. Please try again later." }.to_json ]
    ]
  end
end
