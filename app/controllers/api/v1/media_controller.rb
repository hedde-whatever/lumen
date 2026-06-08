class Api::V1::MediaController < ApplicationController
  include Authenticatable
  before_action :set_event
  before_action :set_medium, only: [ :destroy ]

  MEDIA_LIMIT = 10

  def index
    items = @event.media.map { |m| medium_json(m) }
    render json: { items: items, limit: MEDIA_LIMIT, remaining: MEDIA_LIMIT - items.count }
  end

  def create
    if @event.media.count >= MEDIA_LIMIT
      render json: { error: "Event has reached the #{MEDIA_LIMIT} photo limit" }, status: :unprocessable_entity
      return
    end

    file   = params.require(:file)
    medium = @event.media.build(user: @current_user)
    medium.photo.attach(file)

    if medium.save
      render json: medium_json(medium), status: :created
    else
      medium.photo.purge if medium.photo.attached?
      render json: { errors: medium.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
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
    medium.as_json(only: [ :id, :created_at ]).merge(
      url:           medium.presigned_url,
      thumbnail_url: medium.thumbnail_url
    )
  end
end
