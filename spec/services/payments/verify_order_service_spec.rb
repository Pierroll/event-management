require 'rails_helper'

RSpec.describe Payments::VerifyOrderService do
  let(:category) { Category.create!(name: "Test", slug: "test-vos") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.vos@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.vos@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento VOS",
      description: "Test event for verify order service.",
      city: "Lima",
      address: "Av. Test",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/vos.jpg")
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
      quantity: 2,
      unit_price: ticket_type.price,
      status: :pending,
      expires_at: 15.minutes.from_now
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
    context "when order is paid" do
      let(:order_id) { "mock_ord_success" }

      it "creates an approved payment record" do
        payment = described_class.call(booking, order_id)
        expect(payment).to be_approved
        expect(payment.provider_charge_id).to eq(order_id)
      end

      it "confirms the booking" do
        described_class.call(booking, order_id)
        expect(booking.reload).to be_confirmed
      end
    end

    context "when order is expired" do
      let(:order_id) { "mock_ord_fail_expired" }

      it "raises an OrderError" do
        expect {
          described_class.call(booking, order_id)
        }.to raise_error(Payments::VerifyOrderService::OrderError, /La orden de pago ha expirado/)
      end

      it "does not confirm the booking" do
        described_class.call(booking, order_id) rescue nil
        expect(booking.reload).to be_pending
      end
    end

    context "when booking is expired" do
      let(:order_id) { "mock_ord_success" }
      before { booking.update!(expires_at: 5.minutes.ago) }

      it "raises an OrderError" do
        expect {
          described_class.call(booking, order_id)
        }.to raise_error(Payments::VerifyOrderService::OrderError, "La reserva ya expiró")
      end
    end
  end
end
