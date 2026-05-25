class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from Errors::Unauthorized,         with: :render_unauthorized

  private

  def render_not_found
    render json: { error: "Not found" }, status: :not_found
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
