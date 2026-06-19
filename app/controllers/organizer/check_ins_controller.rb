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

      # Atomic check-in: single SQL UPDATE with WHERE condition.
      # If two organizers scan the same ticket simultaneously, PostgreSQL
      # serializes the writes — only the first one succeeds (updated == 1).
      updated = Ticket.where(id: @ticket.id, status: :active)
                      .update_all(status: :used, checked_in_at: Time.current)

      if updated == 1
        render json: {
          success: true,
          attendee_name: @ticket.attendee_name,
          ticket_id: @ticket.id
        }
      else
        render json: { error: "Este ticket ya fue usado" }, status: :conflict
      end
    end

  end
end
