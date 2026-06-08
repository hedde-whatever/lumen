require "net/http"
require "json"

class JwksService
  CACHE_TTL = 1.hour

  def self.fetch(uri)
    Rails.cache.fetch("jwks:#{uri}", expires_in: CACHE_TTL) do
      JSON.parse(Net::HTTP.get(URI(uri)))
    end
  end
end
