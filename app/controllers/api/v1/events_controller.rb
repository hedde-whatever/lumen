class Api::V1::EventsController < ApplicationController
  include Authenticatable
  before_action :set_event, only: [:show, :update, :destroy]

  def index
    events = @current_user.events
                          .chronological
                          .includes(:media)
                          .page(params[:page])
                          .per(params[:per_page] || 20)
    render json: events.as_json(include: { media: { only: [:id, :path, :created_at] } })
  end

  def show
    render json: @event.as_json(include: { media: { only: [:id, :path, :created_at] } })
  end

  def create
    event = @current_user.events.build(event_params)
    if event.save
      render json: event, status: :created
    else
      render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @event.update(event_params)
      render json: @event
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    head :no_content
  end

  private

  def set_event
    @event = @current_user.events.find(params[:id])
  end

  def event_params
    params.permit(:name, :date, :country_name, :country_code, :region_name,
                  :city, :full_address, :address, :feature_type, :lat, :lng, :note)
  end
end
