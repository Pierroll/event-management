# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentPolicy, type: :policy do
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

  let(:pending_booking) do
    Booking.create!(user: user, event: event, ticket_type: ticket_type,
                    quantity: 1, unit_price: 50, status: :pending)
  end
  let(:confirmed_booking) do
    Booking.create!(user: user, event: event, ticket_type: ticket_type,
                    quantity: 1, unit_price: 50, status: :confirmed)
  end
  let(:expired_booking) do
    Booking.create!(user: user, event: event, ticket_type: ticket_type,
                    quantity: 1, unit_price: 50, status: :expired)
  end
  let(:other_pending_booking) do
    Booking.create!(user: other_user, event: event, ticket_type: ticket_type,
                    quantity: 1, unit_price: 50, status: :pending)
  end

  let(:payment) { pending_booking.build_payment }
  let(:confirmed_payment) { confirmed_booking.build_payment }
  let(:expired_payment) { expired_booking.build_payment }
  let(:other_payment) { other_pending_booking.build_payment }

  permissions :show? do
    it "allows the booking owner" do
      expect(subject).to permit(user, payment)
    end

    it "allows admin" do
      expect(subject).to permit(admin, payment)
    end

    it "denies other users" do
      expect(subject).not_to permit(other_user, payment)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, payment)
    end
  end

  permissions :create? do
    it "allows the booking owner on a pending booking" do
      expect(subject).to permit(user, payment)
    end

    it "allows admin on a pending booking" do
      expect(subject).to permit(admin, payment)
    end

    it "denies create on a confirmed booking" do
      expect(subject).not_to permit(user, confirmed_payment)
    end

    it "denies create on an expired booking" do
      expect(subject).not_to permit(user, expired_payment)
    end

    it "denies other users" do
      expect(subject).not_to permit(other_user, payment)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, payment)
    end
  end
end
