class Api::V1::AuthController < ApplicationController
  include Authenticatable
  include TokenIssuable
  skip_before_action :authenticate_request!, only: [ :register, :login, :refresh ]

  def register
    user = User.new(register_params)
    if user.save
      render json: token_response(user), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email].to_s.downcase)
    if user&.authenticate(params[:password])
      render json: token_response(user)
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def me
    render json: { user: user_json(@current_user) }
  end

  def refresh
    record = RefreshToken.valid.find_by(token: params[:refresh_token])
    unless record
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    record.revoke!
    render json: token_response(record.user)
  end

  def logout
    record = @current_user.refresh_tokens.find_by(token: params[:refresh_token])
    record&.revoke!
    head :no_content
  end

  private

  def register_params
    params.permit(:name, :email, :password, :password_confirmation)
  end


end
