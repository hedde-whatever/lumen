module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
  end

  private

  def authenticate_request!
    token = bearer_token
    raise Errors::Unauthorized, "Missing token" if token.blank?

    payload = JwtService.decode(token)
    @current_user = User.find(payload[:sub])
  rescue Errors::InvalidToken, ActiveRecord::RecordNotFound
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def bearer_token
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end
end
