# frozen_string_literal: true

class TicketsController < ApplicationController
  before_action :authenticate_user!

  def update
    @ticket = Ticket.find(params[:id])
    authorize @ticket

    if @ticket.update(ticket_params)
      redirect_to booking_path(@ticket.booking), notice: "El nombre del asistente fue actualizado con éxito."
    else
      redirect_to booking_path(@ticket.booking), alert: "No se pudo actualizar el nombre del asistente: #{@ticket.errors.full_messages.to_sentence}"
    end
  end

  private

  def ticket_params
    params.require(:ticket).permit(:attendee_name)
  end
end
