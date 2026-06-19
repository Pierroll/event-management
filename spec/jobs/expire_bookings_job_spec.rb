require 'rails_helper'

RSpec.describe ExpireBookingsJob, type: :job do
  let(:category) { Category.create!(name: "Test", slug: "test-exp") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.exp@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.exp@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento Exp",
      description: "Test event for expiration job.",
      city: "Lima",
      address: "Av. Test",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/exp.jpg")
    e.ticket_types.build(name: "General", price: 50, quantity_total: 100)
    e.save!
    e
  end
  let(:ticket_type) { event.ticket_types.first }

  it "expires pending bookings past their expires_at" do
    expired = Booking.create!(
      user: user, event: event, ticket_type: ticket_type,
      quantity: 1, unit_price: 50, status: :pending, expires_at: 5.minutes.ago
    )
    not_expired = Booking.create!(
      user: user, event: event, ticket_type: ticket_type,
      quantity: 1, unit_price: 50, status: :pending, expires_at: 5.minutes.from_now
    )
    confirmed = Booking.create!(
      user: user, event: event, ticket_type: ticket_type,
      quantity: 1, unit_price: 50, status: :confirmed
    )

    ExpireBookingsJob.perform_now

    expect(expired.reload).to be_expired
    expect(not_expired.reload).to be_pending
    expect(confirmed.reload).to be_confirmed
  end

  it "does not expire bookings without expires_at" do
    no_expiry = Booking.create!(
      user: user, event: event, ticket_type: ticket_type,
      quantity: 1, unit_price: 50, status: :pending
    )

    ExpireBookingsJob.perform_now
    expect(no_expiry.reload).to be_pending
  end

  it "does not expire bookings with a pending payment" do
    booking = Booking.create!(
      user: user, event: event, ticket_type: ticket_type,
      quantity: 1, unit_price: 50, status: :pending, expires_at: 5.minutes.ago
    )
    Payment.create!(booking: booking, provider: "mock", status: :pending)

    ExpireBookingsJob.perform_now
    expect(booking.reload).to be_pending
  end

  it "expires bookings with a declined payment" do
    booking = Booking.create!(
      user: user, event: event, ticket_type: ticket_type,
      quantity: 1, unit_price: 50, status: :pending, expires_at: 5.minutes.ago
    )
    Payment.create!(booking: booking, provider: "mock", status: :declined)

    ExpireBookingsJob.perform_now
    expect(booking.reload).to be_expired
  end
end
