# frozen_string_literal: true

module Payments
  class VerifyOrderService
    class OrderError < StandardError; end

    def self.call(booking, order_id)
      new(booking, order_id).call
    end

    def initialize(booking, order_id)
      @booking = booking
      @order_id = order_id
    end

    def call
      raise OrderError, "La reserva ya expiró" if @booking.expired_unpaid?

      @booking.with_lock do
        raise OrderError, "La reserva ya expiró" if @booking.expired_unpaid?
        raise OrderError, "La reserva ya fue confirmada" if @booking.confirmed?

        gateway = PaymentGateway.instance
        result = gateway.get_order(order_id: @order_id)

        # Culqi order states: paid, pending, expired
        if result[:state] == "paid"
          payment = @booking.create_payment!(
            provider: PaymentGateway.gateway_class.name.demodulize,
            provider_charge_id: @order_id,
            status: :approved,
            raw_response: JSON.parse(result[:raw_response])
          )

          @booking.update!(status: :confirmed)
          Tickets::GenerateService.call(@booking)
          payment
        else
          state_desc = case result[:state]
                       when "expired" then "La orden de pago ha expirado"
                       when "pending" then "El pago aún está pendiente"
                       else "La orden no se encuentra pagada (Estado: #{result[:state]})"
                       end
          raise OrderError, state_desc
        end
      end
    rescue PaymentGateway::ChargeError => e
      raise OrderError, e.message
    end
  end
end
