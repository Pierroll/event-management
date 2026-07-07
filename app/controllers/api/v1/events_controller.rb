module Api
  module V1
    class EventsController < BaseController
      def index
        @events = Event.published.includes(:category, :organizer).order(start_date: :asc)
        @events = @events.page(params[:page]).per(params[:per_page] || 20)
      end

      def show
        @event = Event.published.includes(:category, :organizer, :ticket_types).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Event not found" }, status: :not_found
      end
    end
  end
end
