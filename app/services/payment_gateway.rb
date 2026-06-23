# frozen_string_literal: true

module PaymentGateway
  class NotConfiguredError < StandardError; end
  class ChargeError < StandardError; end

  # Subclasses must implement payment methods.
  class Base
    def charge(amount_cents:, currency_code:, description:, email:, source_id:)
      raise NotImplementedError, "#{self.class} must implement #charge"
    end

    def create_order(amount_cents:, currency_code:, description:, email:, first_name:, last_name:, phone_number:, expires_at:)
      raise NotImplementedError, "#{self.class} must implement #create_order"
    end

    def get_order(order_id:)
      raise NotImplementedError, "#{self.class} must implement #get_order"
    end

    def refund(charge_id:, amount_cents:, reason:)
      raise NotImplementedError, "#{self.class} must implement #refund"
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
