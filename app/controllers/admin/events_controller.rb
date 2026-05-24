module Admin
  class EventsController < BaseController
    def index
      @events = Event.includes(:organizer, :category).page(params[:page]).per(10)
    end

    def show
      @event = Event.find(params[:id])
    end

    def update
      @event = Event.find(params[:id])
      if @event.update(event_status_params)
        redirect_to admin_event_path(@event), notice: "Estado del evento actualizado exitosamente."
      else
        redirect_to admin_event_path(@event), alert: @event.errors.full_messages.to_sentence
      end
    end

    private

    def event_status_params
      params.require(:event).permit(:status)
    end
  end
end
