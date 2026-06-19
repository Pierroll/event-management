# frozen_string_literal: true

module Payments
  class ChargeService
    class ChargeError < StandardError; end

    def self.call(booking, source_id)
      new(booking, source_id).call
    end

    def initialize(booking, source_id)
      @booking = booking
      @source_id = source_id
    end

    def call
      raise ChargeError, "La reserva ya expiró" if @booking.expired_unpaid?

      @booking.with_lock do
        # Re-check state after acquiring the row lock — another process
        # may have confirmed or expired this booking while we were waiting.
        raise ChargeError, "La reserva ya expiró" if @booking.expired_unpaid?
        raise ChargeError, "La reserva ya fue confirmada" if @booking.confirmed?

        amount_cents = (@booking.total_price * 100).to_i

        gateway = PaymentGateway.instance
        result = gateway.charge(
          amount_cents: amount_cents,
          currency_code: "PEN",
          description: "Booking ##{@booking.id} - #{@booking.event.name}",
          email: @booking.user.email,
          source_id: @source_id
        )

        payment = @booking.create_payment!(
          provider: PaymentGateway.gateway_class.name.demodulize,
          provider_charge_id: result[:charge_id],
          status: result[:success] ? :approved : :declined,
          raw_response: JSON.parse(result[:raw_response])
        )

        if payment.approved?
          @booking.update!(status: :confirmed)
          Tickets::GenerateService.call(@booking)
        end
        payment
      end
    rescue PaymentGateway::ChargeError => e
      raise ChargeError, e.message
    end
  end
end
