# frozen_string_literal: true

class TicketMailer < ApplicationMailer
  def purchase_confirmation(booking)
    @booking = booking
    @event = booking.event
    @ticket_type = booking.ticket_type
    @total = booking.total_price

    mail(to: booking.user.email, subject: "Compra confirmada — #{@event.name}")
  end
end
