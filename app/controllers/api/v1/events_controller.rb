module Api
  module V1
    class EventsController < BaseController
      def index
        @events = Event.published.includes(:category, :organizer).order(start_date: :asc)

        # Filtros
        @events = @events.where(category_id: params[:category_id]) if params[:category_id].present?
        @events = @events.where("city ILIKE ?", "%#{params[:city]}%") if params[:city].present?
        
        if params[:location].present?
          radius = params[:radius].present? ? params[:radius].to_i : 50
          @events = @events.near(params[:location], radius, units: :km)
        end

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
