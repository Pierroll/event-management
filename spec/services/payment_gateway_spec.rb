require 'rails_helper'

RSpec.describe PaymentGateway do
  describe ".instance" do
    around do |example|
      old_val = ENV["PAYMENT_GATEWAY"]
      ENV["PAYMENT_GATEWAY"] = "MockGateway"
      PaymentGateway.remove_instance_variable(:@instance) if PaymentGateway.instance_variable_defined?(:@instance)
      example.run
    ensure
      ENV["PAYMENT_GATEWAY"] = old_val
      PaymentGateway.remove_instance_variable(:@instance) if PaymentGateway.instance_variable_defined?(:@instance)
    end

    it "returns a MockGateway instance by default" do
      expect(described_class.instance).to be_a(PaymentGateway::MockGateway)
    end

    it "memoizes the instance" do
      expect(described_class.instance.object_id).to eq(described_class.instance.object_id)
    end
  end

  describe ".gateway_class" do
    it "resolves MockGateway" do
      expect(described_class.gateway_class).to eq(PaymentGateway::MockGateway)
    end
  end
end
