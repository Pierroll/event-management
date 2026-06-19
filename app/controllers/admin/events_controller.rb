module Admin
  class EventsController < BaseController
    include EventScoping

    before_action :set_event, only: [:show, :edit, :update]

    def index
      @events = Event.includes(:organizer, :category, :ticket_types).page(params[:page]).per(10)
    end

    def show
    end

    def edit
    end

    def update
      if @event.update(event_params)
        redirect_to admin_event_path(@event), notice: "Evento actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def event_params
      params.require(:event).permit(
        :name, :description, :city, :address, :start_date, :end_date,
        :currency, :max_capacity, :status, :category_id,
        :latitude, :longitude,
        ticket_types_attributes: [:id, :name, :price, :quantity_total, :_destroy]
      )
    end
  end
end
