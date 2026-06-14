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

    @current_user = User.find_by(clerk_id: clerk_user.id) || begin
      email = clerk_user.email_addresses.first&.email_address
      name  = [ clerk_user.first_name, clerk_user.last_name ].compact.join(" ").presence ||
              email&.split("@")&.first ||
              "User"
      User.create!(clerk_id: clerk_user.id, email: email, name: name)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      User.find_by!(clerk_id: clerk_user.id)
    end
  end
end
