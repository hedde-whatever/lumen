class Api::V1::MediaController < ApplicationController
  include Authenticatable
  before_action :set_event
  before_action :set_medium, only: [ :destroy ]

  def index
    render json: @event.media.map { |m| medium_json(m) }
  end

  def create
    if @event.media.count >= 10
      render json: { error: "Event has reached the 10 photo limit" }, status: :unprocessable_entity
      return
    end

    file = params.require(:file)
    key  = S3UploadService.upload(
      file:     file,
      user_id:  @current_user.id,
      event_id: @event.id
    )
    medium = @event.media.create!(user: @current_user, path: key)
    render json: medium_json(medium), status: :created
  end

  def destroy
    S3UploadService.delete(key: @medium.path)
    @medium.destroy
    head :no_content
  end

  private

  def set_event
    @event = @current_user.events.find(params[:event_id])
  end

  def set_medium
    @medium = @event.media.find(params[:id])
  end

  def medium_json(medium)
    medium.as_json(only: [ :id, :path, :created_at ]).merge(url: medium.presigned_url)
  end
end
