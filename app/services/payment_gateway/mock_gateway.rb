# frozen_string_literal: true

module PaymentGateway
  # Mock gateway for development/test environments.
  # "Approves" any charge with valid params, "declines" if amount is 0.
  class MockGateway < Base
    # Culqi test card that always approves: 4111111111111111
    APPROVED_CARD_PREFIX = "411111".freeze

    def charge(amount_cents:, currency_code: "PEN", description: nil, email: nil, source_id:)
      amount_cents = amount_cents.to_i

      if amount_cents <= 0
        raise ChargeError, "El monto debe ser mayor a 0"
      end

      success = source_id.to_s.start_with?(APPROVED_CARD_PREFIX)
      charge_id = success ? "mock_ch_#{SecureRandom.hex(12)}" : nil

      {
        success: success,
        charge_id: charge_id,
        raw_response: {
          id: charge_id,
          object: "charge",
          amount: amount_cents,
          currency_code: currency_code,
          description: description,
          email: email,
          outcome: {
            type: success ? "authorized" : "declined",
            code: success ? "manual_approved" : "manual_declined"
          }
        }.to_json
      }
    end

    def create_order(amount_cents:, currency_code: "PEN", description:, email:, first_name:, last_name:, phone_number: nil, expires_at:)
      amount_cents = amount_cents.to_i
      if amount_cents <= 0
        raise ChargeError, "El monto debe ser mayor a 0"
      end

      order_id = "mock_ord_#{SecureRandom.hex(12)}"
      {
        success: true,
        order_id: order_id,
        raw_response: {
          id: order_id,
          object: "order",
          amount: amount_cents,
          currency_code: currency_code,
          state: "created"
        }.to_json
      }
    end

    def get_order(order_id:)
      state = order_id.to_s.include?("fail") ? "expired" : "paid"
      {
        success: true,
        state: state,
        raw_response: {
          id: order_id,
          object: "order",
          state: state
        }.to_json
      }
    end
  end
end
