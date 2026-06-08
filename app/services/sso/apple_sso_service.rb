require "jwt"

module Sso
  class AppleSsoService
    JWKS_URI = "https://appleid.apple.com/auth/keys"
    ISSUER   = "https://appleid.apple.com"

    def self.call(id_token)
      allowed_audiences = ENV.fetch("APPLE_CLIENT_IDS").split(",").map(&:strip)

      # Decode header only (no verification) to check aud before full decode
      unverified_payload, = JWT.decode(id_token, nil, false)
      aud = unverified_payload["aud"]
      unless allowed_audiences.include?(aud)
        raise Errors::SsoVerificationFailed, "Invalid audience: #{aud}"
      end

      jwks    = JWT::JWK::Set.new(JwksService.fetch(JWKS_URI))
      payload, = JWT.decode(
        id_token,
        nil,
        true,
        algorithms:        [ "RS256" ],
        jwks:              jwks,
        iss:               ISSUER,
        verify_iss:        true,
        aud:               aud,
        verify_aud:        true,
        verify_expiration: true
      )

      { sub: payload["sub"], email: payload["email"], name: payload["name"] }
    rescue JWT::DecodeError, JWT::JWKError => e
      raise Errors::SsoVerificationFailed, e.message
    end
  end
end
