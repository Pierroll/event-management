# frozen_string_literal: true

class ExpireBookingsJob < ApplicationJob
  queue_as :default

  def perform
    # Expire pending bookings past their expiry, EXCEPT those with a payment
    # in progress (status: pending). This prevents expiring a booking while
    # ChargeService is processing a payment inside a pessimistic lock.
    expired = Booking.pending
      .where("expires_at < ?", Time.current)
      .where.not(
        id: Payment.where(status: :pending).select(:booking_id)
      )
      .update_all(status: :expired)

    Rails.logger.info "[ExpireBookingsJob] Expired #{expired} pending bookings" if expired > 0
  end
end
