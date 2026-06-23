# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaymentGateway::CulqiGateway, type: :service do
  subject(:gateway) { described_class.new }

  let(:amount_cents) { 5000 }
  let(:currency_code) { "PEN" }
  let(:description) { "Test Charge" }
  let(:email) { "user@test.com" }
  let(:source_id) { "tkn_test_12345" }
  let(:private_key) { "sk_test_1234567890" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("CULQI_PRIVATE_KEY").and_return(private_key)
  end

  describe "#charge" do
    context "when charge is successful" do
      let(:mock_response_body) do
        {
          id: "chr_test_abc123",
          object: "charge",
          amount: amount_cents,
          currency_code: currency_code,
          outcome: {
            type: "authorized",
            code: "manual_approved"
          }
        }.to_json
      end

      before do
        mock_response = instance_double(
          Net::HTTPResponse,
          code: "201",
          body: mock_response_body
        )
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(mock_response)
      end

      it "returns a hash indicating success and the charge id" do
        result = gateway.charge(
          amount_cents: amount_cents,
          currency_code: currency_code,
          description: description,
          email: email,
          source_id: source_id
        )

        expect(result[:success]).to be true
        expect(result[:charge_id]).to eq("chr_test_abc123")
        expect(result[:raw_response]).to eq(mock_response_body)
      end
    end

    context "when charge fails with a card error" do
      let(:mock_response_body) do
        {
          object: "error",
          type: "card_error",
          merchant_message: "La tarjeta no tiene fondos suficientes.",
          user_message: "Fondos insuficientes en la tarjeta."
        }.to_json
      end

      before do
        mock_response = instance_double(
          Net::HTTPResponse,
          code: "402",
          body: mock_response_body
        )
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(mock_response)
      end

      it "raises a ChargeError with the user-friendly error message" do
        expect {
          gateway.charge(
            amount_cents: amount_cents,
            currency_code: currency_code,
            description: description,
            email: email,
            source_id: source_id
          )
        }.to raise_error(PaymentGateway::ChargeError, "Fondos insuficientes en la tarjeta.")
      end
    end

    context "when CULQI_PRIVATE_KEY is missing" do
      let(:private_key) { nil }

      it "raises a ChargeError" do
        expect {
          gateway.charge(
            amount_cents: amount_cents,
            currency_code: currency_code,
            description: description,
            email: email,
            source_id: source_id
          )
        }.to raise_error(PaymentGateway::ChargeError, /La llave privada de Culqi no está configurada/)
      end
    end

    context "when amount is invalid" do
      it "raises a ChargeError for amount <= 0" do
        expect {
          gateway.charge(
            amount_cents: 0,
            currency_code: currency_code,
            description: description,
            email: email,
            source_id: source_id
          )
        }.to raise_error(PaymentGateway::ChargeError, "El monto debe ser mayor a 0")
      end
    end

    context "when there is a network error" do
      before do
        allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Timeout::Error.new("timeout"))
      end

      it "raises a ChargeError indicating connection issues" do
        expect {
          gateway.charge(
            amount_cents: amount_cents,
            currency_code: currency_code,
            description: description,
            email: email,
            source_id: source_id
          )
        }.to raise_error(PaymentGateway::ChargeError, /Error de conexión con la pasarela de pagos/)
      end
    end
  end

  describe "#create_order" do
    let(:expires_at) { 1.day.from_now }

    context "when order creation is successful" do
      let(:mock_response_body) do
        {
          id: "ord_test_abc123",
          object: "order",
          amount: amount_cents,
          currency_code: currency_code
        }.to_json
      end

      before do
        mock_response = instance_double(
          Net::HTTPResponse,
          code: "201",
          body: mock_response_body
        )
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(mock_response)
      end

      it "returns a hash indicating success and the order id" do
        result = gateway.create_order(
          amount_cents: amount_cents,
          currency_code: currency_code,
          description: description,
          email: email,
          first_name: "John",
          last_name: "Doe",
          expires_at: expires_at
        )

        expect(result[:success]).to be true
        expect(result[:order_id]).to eq("ord_test_abc123")
      end
    end
  end

  describe "#get_order" do
    let(:order_id) { "ord_test_abc123" }

    context "when order retrieval is successful" do
      let(:mock_response_body) do
        {
          id: order_id,
          object: "order",
          state: "paid"
        }.to_json
      end

      before do
        mock_response = instance_double(
          Net::HTTPResponse,
          code: "200",
          body: mock_response_body
        )
        allow_any_instance_of(Net::HTTP).to receive(:request).and_return(mock_response)
      end

      it "returns a hash with success and the order state" do
        result = gateway.get_order(order_id: order_id)
        expect(result[:success]).to be true
        expect(result[:state]).to eq("paid")
      end
    end
  end
end
