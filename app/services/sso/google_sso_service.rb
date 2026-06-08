require "jwt"

module Sso
  class GoogleSsoService
    JWKS_URI = "https://www.googleapis.com/oauth2/v3/certs"
    ISSUER   = "https://accounts.google.com"

    def self.call(id_token)
      jwks    = JWT::JWK::Set.new(JwksService.fetch(JWKS_URI))
      payload, = JWT.decode(
        id_token,
        nil,
        true,
        algorithms:        [ "RS256" ],
        jwks:              jwks,
        iss:               ISSUER,
        verify_iss:        true,
        aud:               ENV.fetch("GOOGLE_CLIENT_ID"),
        verify_aud:        true,
        verify_expiration: true
      )

      { sub: payload["sub"], email: payload["email"], name: payload["name"] }
    rescue JWT::DecodeError, JWT::JWKError => e
      raise Errors::SsoVerificationFailed, e.message
    end
  end
end
