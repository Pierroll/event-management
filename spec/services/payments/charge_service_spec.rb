require 'rails_helper'

RSpec.describe Payments::ChargeService do
  let(:category) { Category.create!(name: "Test", slug: "test-cs") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.cs@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.cs@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento CS",
      description: "Test event for charge service.",
      city: "Lima",
      address: "Av. Test",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/cs.jpg")
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
    # Ensure MockGateway is used
    old_val = ENV["PAYMENT_GATEWAY"]
    ENV["PAYMENT_GATEWAY"] = "MockGateway"
    PaymentGateway.remove_instance_variable(:@instance) if PaymentGateway.instance_variable_defined?(:@instance)
  end

  after do
    ENV["PAYMENT_GATEWAY"] = nil
    PaymentGateway.remove_instance_variable(:@instance) if PaymentGateway.instance_variable_defined?(:@instance)
  end

  describe ".call" do
    context "with valid payment" do
      let(:token_id) { "4111111111111111" }

      it "creates an approved payment" do
        payment = described_class.call(booking, token_id)
        expect(payment).to be_approved
        expect(payment.provider).to eq("MockGateway")
        expect(payment.provider_charge_id).to start_with("mock_ch_")
      end

      it "confirms the booking" do
        described_class.call(booking, token_id)
        expect(booking.reload).to be_confirmed
      end

      it "stores the raw response" do
        payment = described_class.call(booking, token_id)
        expect(payment.raw_response).to be_a(Hash)
        expect(payment.raw_response["outcome"]["type"]).to eq("authorized")
      end
    end

    context "with declined payment" do
      let(:token_id) { "4242424242424242" }

      it "creates a declined payment" do
        payment = described_class.call(booking, token_id)
        expect(payment).to be_declined
      end

      it "does NOT confirm the booking" do
        described_class.call(booking, token_id)
        expect(booking.reload).to be_pending
      end
    end

    context "when called twice (double-charge protection)" do
      let(:token_id) { "4111111111111111" }

      it "raises ChargeError on the second call" do
        described_class.call(booking, token_id)
        expect {
          described_class.call(booking.reload, token_id)
        }.to raise_error(Payments::ChargeService::ChargeError, "La reserva ya fue confirmada")
      end

      it "does not create a second payment" do
        described_class.call(booking, token_id)
        expect {
          described_class.call(booking.reload, token_id) rescue nil
        }.not_to change(Payment, :count)
      end
    end

    context "with expired booking" do
      let(:token_id) { "4111111111111111" }
      before { booking.update!(expires_at: 5.minutes.ago) }

      it "raises ChargeError" do
        expect {
          described_class.call(booking, token_id)
        }.to raise_error(Payments::ChargeService::ChargeError, "La reserva ya expiró")
      end

      it "does not create a payment" do
        expect {
          described_class.call(booking, token_id) rescue nil
        }.not_to change(Payment, :count)
      end
    end
  end
end
