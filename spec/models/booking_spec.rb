# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Booking, type: :model do
  let(:category) { Category.create!(name: "Test", slug: "test-bkg") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.bkg@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.bkg@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento Booking",
      description: "Test event for booking model.",
      city: "Lima", address: "Av. Test",
      start_date: 1.day.from_now, end_date: 1.day.from_now + 2.hours,
      currency: "PEN", category: category, organizer: organizer, status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/bkg.jpg")
    e.ticket_types.build(name: "General", price: 50, quantity_total: 100, max_per_order: 2)
    e.save!
    e
  end
  let(:ticket_type) { event.ticket_types.first }

  describe "validations" do
    context "when ticket type has max_per_order set" do
      it "allows booking quantity within limit" do
        booking = Booking.new(user: user, event: event, ticket_type: ticket_type, quantity: 2, unit_price: ticket_type.price, status: :pending)
        expect(booking).to be_valid
      end

      it "denies booking quantity exceeding limit" do
        booking = Booking.new(user: user, event: event, ticket_type: ticket_type, quantity: 3, unit_price: ticket_type.price, status: :pending)
        expect(booking).not_to be_valid
        expect(booking.errors[:quantity]).to include(/supera el límite permitido/)
      end

      it "denies subsequent booking that cumulatively exceeds limit" do
        Booking.create!(user: user, event: event, ticket_type: ticket_type, quantity: 1, unit_price: ticket_type.price, status: :confirmed)
        
        # Second booking of 1 ticket: total is 2, which is equal to max_per_order (valid)
        booking2 = Booking.new(user: user, event: event, ticket_type: ticket_type, quantity: 1, unit_price: ticket_type.price, status: :pending)
        expect(booking2).to be_valid
        booking2.save!

        # Third booking of 1 ticket: total becomes 3, exceeding the limit of 2 (invalid)
        booking3 = Booking.new(user: user, event: event, ticket_type: ticket_type, quantity: 1, unit_price: ticket_type.price, status: :pending)
        expect(booking3).not_to be_valid
        expect(booking3.errors[:quantity]).to include(/supera el límite permitido/)
      end

      it "ignores canceled or expired bookings when calculating cumulative total" do
        Booking.create!(user: user, event: event, ticket_type: ticket_type, quantity: 2, unit_price: ticket_type.price, status: :canceled)
        Booking.create!(user: user, event: event, ticket_type: ticket_type, quantity: 2, unit_price: ticket_type.price, status: :expired)

        # Since prior bookings are canceled/expired, a new booking of 2 tickets is valid
        booking = Booking.new(user: user, event: event, ticket_type: ticket_type, quantity: 2, unit_price: ticket_type.price, status: :pending)
        expect(booking).to be_valid
      end
    end
  end
end
