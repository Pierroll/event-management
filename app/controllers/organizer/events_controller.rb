module Organizer
  class EventsController < BaseController
    before_action :set_event, only: [:show, :edit, :update, :destroy]

    def index
      @events = policy_scope(Event).where(organizer_id: current_user.id).page(params[:page]).per(10)
    end

    def show
      authorize @event
    end

    def new
      @event = Event.new
      authorize @event
    end

    def create
      # Se autoriza primero con un evento vacío para validar que el rol pueda crear
      authorize Event.new

      @event = Events::CreateService.call(current_user, event_params)

      if @event.persisted?
        redirect_to organizer_event_path(@event), notice: "Evento creado exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @event
    end

    def update
      authorize @event

      @event = Events::UpdateService.call(@event, event_params)

      if @event.errors.empty?
        redirect_to (request.referrer || organizer_events_path), notice: "Evento actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @event
      @event.destroy
      redirect_to organizer_events_path, notice: "Evento eliminado exitosamente."
    end

    private

    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(
        :name, :description, :city, :address, :start_date, :end_date,
        :price, :currency, :max_capacity, :status, :category_id,
        :latitude, :longitude,
        :primary_image,
        images: [], remove_image_ids: []
      )
    end
  end
end
