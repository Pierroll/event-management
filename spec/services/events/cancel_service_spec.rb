# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::CancelService do
  let(:category) { Category.create!(name: "Test", slug: "test-ec") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.ec@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.ec@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento EC",
      description: "Test event for cancel service.",
      city: "Lima",
      address: "Av. Test",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/ec.jpg")
    e.ticket_types.build(name: "General", price: 50, quantity_total: 100)
    e.save!
    e
  end
  let(:ticket_type) { event.ticket_types.first }

  # Confirmed booking with successful payment
  let!(:confirmed_booking) do
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
  let!(:confirmed_payment) do
    Payment.create!(
      booking: confirmed_booking,
      provider: "MockGateway",
      provider_charge_id: "mock_ch_success",
      status: :approved,
      raw_response: { id: "mock_ch_success" }
    )
  end
  let!(:confirmed_ticket) { confirmed_booking.tickets.create!(status: :active) }

  # Confirmed booking with failed payment (to test resilience)
  let!(:failed_booking) do
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
  let!(:failed_payment) do
    Payment.create!(
      booking: failed_booking,
      provider: "MockGateway",
      provider_charge_id: "mock_ch_fail_123", # matches the failure check in MockGateway
      status: :approved,
      raw_response: { id: "mock_ch_fail_123" }
    )
  end
  let!(:failed_ticket) { failed_booking.tickets.create!(status: :active) }

  # Pending booking
  let!(:pending_booking) do
    Booking.create!(
      user: user,
      event: event,
      ticket_type: ticket_type,
      quantity: 1,
      unit_price: ticket_type.price,
      status: :pending,
      booked_at: Time.current
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
    it "transitions the event status to canceled" do
      described_class.call(event)
      expect(event.reload).to be_canceled
    end

    it "processes bookings resiliently" do
      results = described_class.call(event)

      expect(results[:success]).to be true
      expect(results[:refunded_count]).to eq(1) # confirmed_booking succeeded
      expect(results[:canceled_pending_count]).to eq(1) # pending_booking succeeded
      expect(results[:failed_bookings].size).to eq(1) # failed_booking failed

      # Check database states
      expect(confirmed_booking.reload).to be_canceled
      expect(confirmed_ticket.reload).to be_canceled
      expect(confirmed_payment.reload).to be_refunded

      expect(pending_booking.reload).to be_canceled

      # The failed booking stays confirmed, and the payment stays approved with error logged
      expect(failed_booking.reload).to be_confirmed
      expect(failed_ticket.reload).to be_active
      expect(failed_payment.reload).to be_approved
      expect(failed_payment.raw_response["refund_error"]).to be_present
    end

    context "when event is already canceled" do
      before { event.update!(status: :canceled) }

      it "raises CancelError" do
        expect {
          described_class.call(event)
        }.to raise_error(Events::CancelService::CancelError, "El evento ya está cancelado")
      end
    end
  end
end
