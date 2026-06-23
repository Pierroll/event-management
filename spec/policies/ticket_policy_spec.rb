# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketPolicy, type: :policy do
  subject { described_class }

  let(:user) { User.create!(name: "User", email: "user@test.com", password: "password123", confirmed_at: Time.current) }
  let(:other_user) { User.create!(name: "Other", email: "other@test.com", password: "password123", confirmed_at: Time.current) }
  let(:admin) do
    User.create!(name: "Admin", email: "admin@test.com", password: "password123", confirmed_at: Time.current).tap do |u|
      u.roles << Role.find_or_create_by!(name: "admin")
    end
  end
  let(:guest) { nil }
  let(:category) { Category.create!(name: "Test", slug: "test-pol") }
  let(:organizer) do
    User.create!(name: "Org", email: "org@test.com", password: "password123", confirmed_at: Time.current).tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:event) do
    e = Event.new(
      name: "Event", description: "description for event", city: "Lima", address: "Av",
      start_date: 1.day.from_now, end_date: 1.day.from_now + 2.hours,
      currency: "PEN", category: category, organizer: organizer, status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/pol.jpg")
    e.ticket_types.build(name: "General", price: 50, quantity_total: 100)
    e.save!
    e
  end
  let(:ticket_type) { event.ticket_types.first }

  let(:confirmed_booking) do
    Booking.create!(user: user, event: event, ticket_type: ticket_type,
                    quantity: 2, unit_price: 50, status: :confirmed)
  end
  let(:pending_booking) do
    Booking.create!(user: user, event: event, ticket_type: ticket_type,
                    quantity: 2, unit_price: 50, status: :pending)
  end

  let(:ticket_confirmed) { Ticket.create!(booking: confirmed_booking, attendee_name: "Original Name", status: :active) }
  let(:ticket_pending) { Ticket.create!(booking: pending_booking, attendee_name: "Original Name", status: :active) }
  let(:ticket_used) { Ticket.create!(booking: confirmed_booking, attendee_name: "Original Name", status: :used) }
  let(:ticket_canceled) { Ticket.create!(booking: confirmed_booking, attendee_name: "Original Name", status: :canceled) }

  permissions :show? do
    it "allows the booking owner" do
      expect(subject).to permit(user, ticket_confirmed)
    end

    it "allows admin" do
      expect(subject).to permit(admin, ticket_confirmed)
    end

    it "denies other users" do
      expect(subject).not_to permit(other_user, ticket_confirmed)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, ticket_confirmed)
    end
  end

  permissions :update? do
    it "allows the booking owner to update active tickets on confirmed bookings" do
      expect(subject).to permit(user, ticket_confirmed)
    end

    it "allows admin to update active tickets on confirmed bookings" do
      expect(subject).to permit(admin, ticket_confirmed)
    end

    it "denies updating tickets on pending bookings" do
      expect(subject).not_to permit(user, ticket_pending)
    end

    it "denies updating used tickets" do
      expect(subject).not_to permit(user, ticket_used)
    end

    it "denies updating canceled tickets" do
      expect(subject).not_to permit(user, ticket_canceled)
    end

    it "denies updating other users' tickets" do
      expect(subject).not_to permit(other_user, ticket_confirmed)
    end

    it "denies updating tickets for guests" do
      expect(subject).not_to permit(guest, ticket_confirmed)
    end
  end
end
