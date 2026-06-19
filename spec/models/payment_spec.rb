require 'rails_helper'

RSpec.describe Payment, type: :model do
  let(:category) { Category.create!(name: "Test", slug: "test-pay") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.pay@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.pay@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento Pago",
      description: "Test event for payment with enough chars.",
      city: "Lima",
      address: "Av. Test",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/pay.jpg")
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
      status: :pending
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      payment = Payment.new(
        booking: booking,
        provider: "mock",
        status: :approved,
        provider_charge_id: "ch_test_123"
      )
      expect(payment).to be_valid
    end

    it "requires a provider" do
      payment = Payment.new(booking: booking, provider: nil)
      expect(payment).not_to be_valid
      expect(payment.errors[:provider]).to include("no puede estar en blanco")
    end

    it "validates uniqueness of provider_charge_id" do
      Payment.create!(booking: booking, provider: "mock", status: :approved, provider_charge_id: "ch_uniq")
      other_booking = Booking.create!(
        user: user, event: event, ticket_type: ticket_type,
        quantity: 1, unit_price: 50, status: :pending
      )
      payment = Payment.new(booking: other_booking, provider: "mock", provider_charge_id: "ch_uniq")
      expect(payment).not_to be_valid
      expect(payment.errors[:provider_charge_id]).to include("ya está en uso")
    end

    it "validates uniqueness of booking" do
      Payment.create!(booking: booking, provider: "mock", status: :approved, provider_charge_id: "ch_bk_uniq")
      payment = Payment.new(booking: booking, provider: "mock", status: :pending)
      expect(payment).not_to be_valid
      expect(payment.errors[:booking]).to include("ya tiene un pago registrado")
    end

    it "allows nil provider_charge_id (pending)" do
      payment = Payment.new(booking: booking, provider: "mock")
      expect(payment).to be_valid
    end
  end

  describe "state machine" do
    it "allows pending -> approved" do
      payment = Payment.new(booking: booking, provider: "mock", status: :pending)
      expect(payment.can_transition_to?(:approved)).to be true
    end

    it "allows pending -> declined" do
      payment = Payment.new(booking: booking, provider: "mock", status: :pending)
      expect(payment.can_transition_to?(:declined)).to be true
    end

    it "allows approved -> refunded" do
      payment = Payment.new(booking: booking, provider: "mock", status: :approved)
      expect(payment.can_transition_to?(:refunded)).to be true
    end

    it "allows approved -> declined" do
      payment = Payment.new(booking: booking, provider: "mock", status: :approved)
      expect(payment.can_transition_to?(:declined)).to be true
    end

    it "rejects declined -> approved (out of order)" do
      payment = Payment.new(booking: booking, provider: "mock", status: :declined)
      expect(payment.can_transition_to?(:approved)).to be false
    end

    it "rejects refunded -> approved (out of order)" do
      payment = Payment.new(booking: booking, provider: "mock", status: :refunded)
      expect(payment.can_transition_to?(:approved)).to be false
    end

    it "rejects refunded -> declined (out of order)" do
      payment = Payment.new(booking: booking, provider: "mock", status: :refunded)
      expect(payment.can_transition_to?(:declined)).to be false
    end

    it "rejects declined -> refunded (out of order)" do
      payment = Payment.new(booking: booking, provider: "mock", status: :declined)
      expect(payment.can_transition_to?(:refunded)).to be false
    end

    it "accepts string status names" do
      payment = Payment.new(booking: booking, provider: "mock", status: :pending)
      expect(payment.can_transition_to?("approved")).to be true
    end

    it "returns false for unknown status" do
      payment = Payment.new(booking: booking, provider: "mock", status: :approved)
      expect(payment.can_transition_to?("unknown")).to be false
    end
  end

  describe "enums" do
    it "defines expected statuses" do
      expect(Payment.statuses).to eq({
        "pending" => 0,
        "approved" => 1,
        "declined" => 2,
        "refunded" => 3
      })
    end
  end

  describe "associations" do
    it "belongs to a booking" do
      payment = Payment.create!(booking: booking, provider: "mock", status: :approved, provider_charge_id: "ch_assoc")
      expect(payment.booking).to eq(booking)
    end

    it "destroys payment when booking is destroyed" do
      payment = Payment.create!(booking: booking, provider: "mock", status: :approved, provider_charge_id: "ch_destroy")
      expect { booking.destroy }.to change { Payment.count }.by(-1)
    end
  end
end
