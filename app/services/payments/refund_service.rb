# frozen_string_literal: true

module Payments
  class RefundService
    class RefundError < StandardError; end

    def self.call(payment)
      new(payment).call
    end

    def initialize(payment)
      @payment = payment
    end

    def call
      raise RefundError, "El pago debe estar aprobado para ser reembolsado" unless @payment.approved?

      error_to_raise = nil

      @payment.with_lock do
        # Re-check status inside lock to prevent race conditions
        raise RefundError, "El pago debe estar aprobado para ser reembolsado" unless @payment.approved?

        amount_cents = (@payment.booking.total_price * 100).to_i

        begin
          gateway = PaymentGateway.instance
          result = gateway.refund(
            charge_id: @payment.provider_charge_id,
            amount_cents: amount_cents,
            reason: "solicitud_comprador"
          )

          # Parse and store raw refund response under "refund_details" key
          refund_data = JSON.parse(result[:raw_response]) rescue { refund_id: result[:refund_id] }
          updated_raw = (@payment.raw_response || {}).merge(
            "refund_details" => refund_data,
            "refunded_at" => Time.current.iso8601
          )

          @payment.update!(
            status: :refunded,
            raw_response: updated_raw
          )
        rescue => e
          error_to_raise = e
        end
      end

      if error_to_raise
        # Save error message inside raw_response JSONB outside the transaction
        updated_raw = (@payment.reload.raw_response || {}).merge(
          "refund_error" => error_to_raise.message,
          "refund_failed_at" => Time.current.iso8601
        )
        @payment.update!(raw_response: updated_raw)

        raise RefundError, "Fallo en pasarela: #{error_to_raise.message}"
      end

      true
    end
  end
end
