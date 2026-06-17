# frozen_string_literal: true

# Handles ticket booking lifecycle:
# - Create: checks availability, locks event row, creates booking
# - Cancel: frees capacity
# Future: add payment step between create and confirm
class BookingService
  class CapacityExceededError < StandardError; end

  def self.create(user, event, quantity: 1)
    new(user, event, quantity).create
  end

  def initialize(user, event, quantity)
    @user = user
    @event = event
    @quantity = quantity.to_i
  end

  def create
    raise CapacityExceededError, "El evento no tiene capacidad disponible" unless available?

    # Lock the event row to prevent race conditions on the last ticket
    ActiveRecord::Base.transaction do
      @event.lock!

      raise CapacityExceededError, "Ya no hay suficientes lugares disponibles" if @event.remaining_capacity < @quantity

      booking = @user.bookings.create!(
        event: @event,
        quantity: @quantity,
        status: :confirmed,
        booked_at: Time.current
      )

      booking
    end
  end

  private

  def available?
    @event.available?
  end
end
