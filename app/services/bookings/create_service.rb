# frozen_string_literal: true

module Bookings
  class CreateService
    class CapacityExceededError < StandardError; end

    def self.call(user, ticket_type, quantity: 1)
      new(user, ticket_type, quantity).call
    end

    def initialize(user, ticket_type, quantity)
      @user = user
      @ticket_type = ticket_type
      @event = ticket_type.event
      @quantity = quantity.to_i
    end

    def call
      raise CapacityExceededError, "Esta entrada ya no está disponible" unless @ticket_type.available?
      raise CapacityExceededError, "El evento alcanzó su aforo máximo" unless @event.available?

      ActiveRecord::Base.transaction do
        @event.lock!
        @ticket_type.lock!

        if @ticket_type.remaining_capacity < @quantity
          raise CapacityExceededError, "Ya no hay suficientes entradas de este tipo"
        end
        if @event.remaining_capacity < @quantity
          raise CapacityExceededError, "El evento alcanzó su aforo máximo"
        end

        @user.bookings.create!(
          event: @event,
          ticket_type: @ticket_type,
          quantity: @quantity,
          unit_price: @ticket_type.price,
          status: :pending,
          booked_at: Time.current
        )
      end
    end
  end
end
