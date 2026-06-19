require 'rails_helper'

RSpec.describe PaymentGateway::MockGateway do
  subject(:gateway) { described_class.new }

  describe "#charge" do
    let(:valid_params) do
      {
        amount_cents: 5000,
        currency_code: "PEN",
        description: "Test charge",
        email: "user@test.com",
        source_id: source_id
      }
    end

    context "with approved card prefix (411111)" do
      let(:source_id) { "4111111111111111" }

      it "returns a successful result" do
        result = gateway.charge(**valid_params)
        expect(result[:success]).to be true
        expect(result[:charge_id]).to start_with("mock_ch_")
        expect(result[:raw_response]).to be_a(String)
      end
    end

    context "with declined card" do
      let(:source_id) { "4242424242424242" }

      it "returns a declined result" do
        result = gateway.charge(**valid_params)
        expect(result[:success]).to be false
        expect(result[:charge_id]).to be_nil
      end
    end

    context "with zero amount" do
      let(:source_id) { "4111111111111111" }

      it "raises ChargeError" do
        expect {
          gateway.charge(**valid_params.merge(amount_cents: 0))
        }.to raise_error(PaymentGateway::ChargeError, "El monto debe ser mayor a 0")
      end
    end
  end
end
