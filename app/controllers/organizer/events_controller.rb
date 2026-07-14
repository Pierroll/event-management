module Organizer
  class EventsController < BaseController
    include EventScoping

    before_action -> { set_event(scope: :organizer) }, only: [:show, :edit, :update, :destroy, :attendees, :cancel]

    def index
      authorize Event
      @events = policy_scope(Event)
                  .includes(:category, :event_images, :ticket_types)
                  .where(organizer_id: current_user.id)
                  .page(params[:page]).per(10)
    end

    def show
      authorize @event
    end

    def attendees
      authorize @event
      @tickets = @event.tickets
                       .includes(:booking => [:user, :ticket_type])
                       .order("tickets.created_at DESC")

      respond_to do |format|
        format.html
        format.csv do
          require 'csv'
          csv_data = CSV.generate(headers: true) do |csv|
            csv << ["ID", "Nombre", "Email", "Tipo de Ticket", "Estado", "Código"]
            @tickets.each do |ticket|
              csv << [
                ticket.id,
                ticket.booking.user.name,
                ticket.booking.user.email,
                ticket.booking.ticket_type.name,
                ticket.status,
                ticket.code
              ]
            end
          end
          send_data csv_data, filename: "asistentes_#{@event.slug || @event.id}.csv", type: "text/csv"
        end
      end
    end

    def cancel
      authorize @event, :cancel?
      
      if @event.update(status: :canceled)
        CancelEventJob.perform_later(@event)
        redirect_to organizer_event_path(@event), notice: "El evento ha sido cancelado y los reembolsos se están procesando en segundo plano."
      else
        redirect_to organizer_event_path(@event), alert: "No se pudo cancelar el evento."
      end
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

    def event_params
      params.require(:event).permit(
        :name, :description, :city, :address, :start_date, :end_date,
        :currency, :max_capacity, :status, :category_id, :check_in_enabled,
        :latitude, :longitude,
        :primary_image,
        images: [], remove_image_ids: [],
        ticket_types_attributes: [:id, :name, :price, :quantity_total, :_destroy]
      )
    end
  end
end
