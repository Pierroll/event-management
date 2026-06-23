# frozen_string_literal: true

module Organizer
  class CheckInsController < BaseController
    include EventScoping

    before_action -> { set_event(scope: :organizer, id_key: :event_id) }

    # GET /organizer/events/:event_id/check_in
    def show
      authorize @event, policy_class: CheckInPolicy
    end

    # POST /organizer/events/:event_id/check_in
    # Recibe params[:qr_code], busca el ticket, lo marca como usado.
    # Respuesta JSON para ser consumida por la cámara JS o por fetch manual.
    def create
      authorize @event, policy_class: CheckInPolicy

      unless @event.check_in_enabled?
        return render json: { error: "El check-in no está activado para este evento" }, status: :forbidden
      end

      @ticket = Ticket.find_by(qr_code: params[:qr_code])

      if @ticket.nil?
        return render json: { error: "Ticket no encontrado" }, status: :not_found
      end

      unless @ticket.booking.event_id == @event.id
        return render json: { error: "Este ticket no pertenece a este evento" }, status: :forbidden
      end

      unless @ticket.active?
        return render json: { error: "Este ticket ya fue usado" }, status: :conflict
      end

      if @ticket.check_in!
        render json: {
          success: true,
          attendee_name: @ticket.attendee_name,
          ticket_id: @ticket.id,
          stats: {
            used: @event.tickets.used.count,
            total: @event.tickets.where(status: [:active, :used]).count
          }
        }
      else
        render json: { error: "Este ticket ya fue usado" }, status: :conflict
      end
    end

    # GET /organizer/events/:event_id/check_in/search
    def search
      authorize @event, policy_class: CheckInPolicy

      unless @event.check_in_enabled?
        return render json: { error: "El check-in no está activado para este evento" }, status: :forbidden
      end

      query = params[:query].to_s.strip
      if query.length >= 2
        tickets = @event.tickets
                        .joins(:booking)
                        .joins("LEFT JOIN users ON bookings.user_id = users.id")
                        .where(
                          "tickets.attendee_name ILIKE :q OR tickets.attendee_email ILIKE :q OR users.name ILIKE :q OR users.email ILIKE :q",
                          q: "%#{query}%"
                        )
                        .limit(10)

        render json: tickets.map { |t|
          {
            id: t.id,
            attendee_name: t.attendee_name.presence || t.booking.user.name,
            qr_code: t.qr_code,
            status: t.status
          }
        }
      else
        render json: []
      end
    end

  end
end
