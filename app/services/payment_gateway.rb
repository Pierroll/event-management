# frozen_string_literal: true

module PaymentGateway
  class NotConfiguredError < StandardError; end
  class ChargeError < StandardError; end

  # Subclasses must implement #charge(amount_cents:, currency_code:, description:, email:, source_id:)
  # which returns a hash with keys: :success, :charge_id, :raw_response.
  class Base
    def charge(amount_cents:, currency_code:, description:, email:, source_id:)
      raise NotImplementedError, "#{self.class} must implement #charge"
    end
  end

  def self.instance
    @instance ||= gateway_class.new
  end

  def self.gateway_class
    class_name = ENV.fetch("PAYMENT_GATEWAY", "MockGateway")
    "PaymentGateway::#{class_name}".constantize
  end
end
