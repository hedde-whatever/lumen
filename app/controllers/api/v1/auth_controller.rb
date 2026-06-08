class Api::V1::AuthController < ApplicationController
  include Authenticatable

  def me
    render json: { user: user_json(@current_user) }
  end

  private

  def user_json(user)
    user.as_json(only: [ :id, :name, :email, :created_at ])
  end
end
