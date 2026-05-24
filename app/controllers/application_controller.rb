class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from Errors::Unauthorized,         with: :render_unauthorized

  private

  def render_not_found(e)
    render json: { error: e.message }, status: :not_found
  end

  def render_unauthorized(e)
    render json: { error: e.message }, status: :unauthorized
  end
end
