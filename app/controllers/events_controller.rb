class EventsController < ApplicationController
  def index
    authorize Event
    sync_selected_city

    base_scope = policy_scope(Event).includes(:category, :organizer, :event_images, :ticket_types)
    @events = Events::SearchQuery.call(base_scope, search_params)
                                 .page(params[:page])
                                 .per(9)
  end

  def show
    @event = Event.includes(:ticket_types).find(params[:id])
    authorize @event
    @comments = @event.comments.includes(:user).order(created_at: :desc)
    @comment = Comment.new
  end

  private

  def search_params
    params.permit(:city, :category_id, :query, :start_date, :end_date, :price_min, :price_max)
  end

  def sync_selected_city
    if params[:city].present?
      if params[:city] == "all"
        cookies[:selected_city] = "all"
        params[:city] = nil
      else
        cookies[:selected_city] = sanitize_city(params[:city])
      end
    elsif cookies[:selected_city].present? && cookies[:selected_city] != "all"
      params[:city] = cookies[:selected_city]
    end
  end

  def sanitize_city(city)
    city.to_s.strip.truncate(100)
  end
end
