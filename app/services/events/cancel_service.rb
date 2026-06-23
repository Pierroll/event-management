# frozen_string_literal: true

module Events
  class CancelService
    class CancelError < StandardError; end

    def self.call(event)
      new(event).call
    end

    def initialize(event)
      @event = event
    end

    def call
      raise CancelError, "El evento ya está cancelado" if @event.canceled?
      raise CancelError, "No se puede cancelar un evento finalizado" if @event.finished?

      # We run the status update in a transaction
      ActiveRecord::Base.transaction do
        @event.update!(status: :canceled)
      end

      # We process bookings outside the main event-status transaction
      # to ensure that if one API request fails or times out, the other successfully completed database writes are saved.
      # This provides resilience and prevents locking database connections.
      results = {
        success: true,
        refunded_count: 0,
        canceled_pending_count: 0,
        failed_bookings: []
      }

      # We load bookings with their associated payment and tickets
      bookings = @event.bookings.includes(:payment, :tickets)

      bookings.each do |booking|
        if booking.pending?
          begin
            booking.with_lock do
              booking.update!(status: :canceled)
              booking.tickets.update_all(status: :canceled)
            end
            results[:canceled_pending_count] += 1
          rescue => e
            Rails.logger.error "[Event Cancellation] Error canceling pending booking ##{booking.id}: #{e.message}"
            results[:failed_bookings] << { booking_id: booking.id, error: e.message }
          end
        elsif booking.confirmed?
          payment = booking.payment
          if payment.nil?
            # Edge case: confirmed booking but no payment record
            Rails.logger.warn "[Event Cancellation] Confirmed booking ##{booking.id} has no payment record."
            begin
              booking.with_lock do
                booking.update!(status: :canceled)
                booking.tickets.update_all(status: :canceled)
              end
              results[:refunded_count] += 1 # Treated as free/manually handled
            rescue => e
              results[:failed_bookings] << { booking_id: booking.id, error: e.message }
            end
          elsif payment.approved?
            begin
              # Run refund service
              Payments::RefundService.call(payment)

              # Update booking and tickets status if refund succeeded
              booking.with_lock do
                booking.update!(status: :canceled)
                booking.tickets.update_all(status: :canceled)
              end
              results[:refunded_count] += 1
            rescue => e
              Rails.logger.error "[Event Cancellation] Refund failed for booking ##{booking.id}: #{e.message}"
              results[:failed_bookings] << { booking_id: booking.id, error: e.message }
            end
          elsif payment.refunded?
            # Already refunded in a previous partial cancel attempt
            begin
              booking.with_lock do
                booking.update!(status: :canceled)
                booking.tickets.update_all(status: :canceled)
              end
              results[:refunded_count] += 1
            rescue => e
              results[:failed_bookings] << { booking_id: booking.id, error: e.message }
            end
          else
            # Payment was declined or is in an unexpected state
            Rails.logger.warn "[Event Cancellation] Booking ##{booking.id} has payment in status #{payment.status}. Canceling without refund."
            begin
              booking.with_lock do
                booking.update!(status: :canceled)
                booking.tickets.update_all(status: :canceled)
              end
              results[:canceled_pending_count] += 1
            rescue => e
              results[:failed_bookings] << { booking_id: booking.id, error: e.message }
            end
          end
        end
      end

      results
    end
  end
end
