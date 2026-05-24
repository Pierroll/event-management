module Admin
  class EventsController < BaseController
    def index
      @events = Event.includes(:organizer, :category).page(params[:page]).per(10)
    end

    def show
      @event = Event.find(params[:id])
    end

    def edit
      @event = Event.find(params[:id])
      @categories = Category.active
    end

    def update
      @event = Event.find(params[:id])

      if @event.update(event_params)
        redirect_to admin_event_path(@event), notice: "Evento actualizado exitosamente."
      else
        @categories = Category.active
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def event_params
      params.require(:event).permit(
        :name, :description, :city, :address, :start_date, :end_date,
        :price, :currency, :max_capacity, :status, :category_id,
        :latitude, :longitude
      )
    end
  end
end
