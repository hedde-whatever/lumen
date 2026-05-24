class JwtService
  ALGORITHM = "HS256"

  def self.encode(user_id:)
    payload = {
      sub: user_id,
      iat: Time.current.to_i,
      exp: ENV.fetch("JWT_EXPIRY_HOURS", 24).to_i.hours.from_now.to_i
    }
    JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret, true, algorithms: [ ALGORITHM ])
    decoded.first.with_indifferent_access
  rescue JWT::DecodeError => e
    raise Errors::InvalidToken, e.message
  end

  def self.secret
    ENV.fetch("JWT_SECRET")
  end
  private_class_method :secret
end
