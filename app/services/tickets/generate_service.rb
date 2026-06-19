# frozen_string_literal: true

module Tickets
  # Generates individual Ticket records for each attendee in a booking.
  #
  # Idempotent: if tickets already exist for the booking, returns early
  # without creating duplicates. Safe to call multiple times.
  class GenerateService
    def self.call(booking)
      new(booking).call
    end

    def initialize(booking)
      @booking = booking
    end

    def call
      # Idempotency guard — never duplicate tickets for the same booking
      return @booking.tickets if @booking.tickets.any?

      tickets = @booking.quantity.times.map do
        @booking.tickets.create!(
          attendee_name: nil,
          attendee_email: nil
        )
      end

      TicketMailer.purchase_confirmation(@booking).deliver_later

      tickets
    end
  end
end
