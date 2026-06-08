module Authenticatable
  extend ActiveSupport::Concern
  include Clerk::Authenticatable

  included do
    before_action :authenticate_request!
  end

  private

  def authenticate_request!
    clerk_user = clerk&.user
    unless clerk_user
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    @current_user = User.find_or_create_by!(clerk_id: clerk_user.id) do |u|
      u.email = clerk_user.email_addresses.first&.email_address
      u.name  = [ clerk_user.first_name, clerk_user.last_name ].compact.join(" ").presence ||
                u.email&.split("@")&.first ||
                "User"
    end
  end
end
