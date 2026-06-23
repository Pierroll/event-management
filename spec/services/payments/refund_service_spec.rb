# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Payments::RefundService do
  let(:category) { Category.create!(name: "Test", slug: "test-rs") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.rs@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.rs@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento RS",
      description: "Test event for refund service.",
      city: "Lima",
      address: "Av. Test",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/rs.jpg")
    e.ticket_types.build(name: "General", price: 50, quantity_total: 100)
    e.save!
    e
  end
  let(:ticket_type) { event.ticket_types.first }
  let(:booking) do
    Booking.create!(
      user: user,
      event: event,
      ticket_type: ticket_type,
      quantity: 1,
      unit_price: ticket_type.price,
      status: :confirmed,
      booked_at: Time.current
    )
  end
  let!(:payment) do
    Payment.create!(
      booking: booking,
      provider: "MockGateway",
      provider_charge_id: "mock_ch_#{SecureRandom.hex(6)}",
      status: :approved,
      raw_response: { id: "mock_ch_abc" }
    )
  end

  before do
    old_val = ENV["PAYMENT_GATEWAY"]
    ENV["PAYMENT_GATEWAY"] = "MockGateway"
    PaymentGateway.remove_instance_variable(:@instance) if PaymentGateway.instance_variable_defined?(:@instance)
  end

  after do
    ENV["PAYMENT_GATEWAY"] = nil
    PaymentGateway.remove_instance_variable(:@instance) if PaymentGateway.instance_variable_defined?(:@instance)
  end

  describe ".call" do
    context "when payment is approved" do
      it "processes the refund successfully" do
        result = described_class.call(payment)
        expect(result).to be true
        expect(payment.reload).to be_refunded
        expect(payment.raw_response["refund_details"]).to be_present
        expect(payment.raw_response["refunded_at"]).to be_present
      end
    end

    context "when gateway fails" do
      before do
        payment.update!(provider_charge_id: "mock_ch_fail_123")
      end

      it "raises RefundError and stores the error inside raw_response" do
        expect {
          described_class.call(payment)
        }.to raise_error(Payments::RefundService::RefundError, /Fallo en pasarela/)

        expect(payment.reload).to be_approved
        expect(payment.raw_response["refund_error"]).to be_present
        expect(payment.raw_response["refund_failed_at"]).to be_present
      end
    end

    context "when payment is not approved" do
      before do
        payment.update!(status: :pending)
      end

      it "raises RefundError and does not attempt refund" do
        expect {
          described_class.call(payment)
        }.to raise_error(Payments::RefundService::RefundError, "El pago debe estar aprobado para ser reembolsado")

        expect(payment.reload).to be_pending
      end
    end
  end
end
