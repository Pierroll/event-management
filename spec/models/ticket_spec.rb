# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ticket, type: :model do
  let(:category) { Category.create!(name: "Test", slug: "test-tkt") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.tkt@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.tkt@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento Ticket",
      description: "Test event for ticket model.",
      city: "Lima", address: "Av. Test",
      start_date: 1.day.from_now, end_date: 1.day.from_now + 2.hours,
      currency: "PEN", category: category, organizer: organizer, status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/tkt.jpg")
    e.ticket_types.build(name: "General", price: 50, quantity_total: 100)
    e.save!
    e
  end
  let(:ticket_type) { event.ticket_types.first }
  let(:booking) do
    Booking.create!(
      user: user, event: event, ticket_type: ticket_type,
      quantity: 2, unit_price: ticket_type.price, status: :confirmed
    )
  end

  describe "validations" do
    it "is valid with default attributes" do
      ticket = booking.tickets.build
      expect(ticket).to be_valid
    end

    it "generates a UUID qr_code on create" do
      ticket = booking.tickets.create!
      expect(ticket.qr_code).to be_present
      expect(ticket.qr_code).to match(/\A[0-9a-f-]+\z/)
    end

    it "enforces unique qr_code" do
      ticket1 = booking.tickets.create!
      ticket2 = booking.tickets.build(qr_code: ticket1.qr_code)
      expect(ticket2).not_to be_valid
      expect(ticket2.errors[:qr_code]).to include("ya está en uso")
    end

    it "defaults status to active" do
      ticket = booking.tickets.create!
      expect(ticket).to be_active
    end

    it "requires a booking" do
      ticket = Ticket.new(qr_code: "abc")
      expect(ticket).not_to be_valid
      expect(ticket.errors[:booking]).to include("debe existir")
    end
  end

  describe "enums" do
    it "defines expected statuses" do
      expect(Ticket.statuses).to eq({
        "active" => 0,
        "used" => 1,
        "canceled" => 2
      })
    end
  end

  describe "scopes" do
    it "filters active tickets" do
      t1 = booking.tickets.create!(status: :active)
      t2 = booking.tickets.create!(status: :used)
      expect(Ticket.active).to contain_exactly(t1)
    end

    it "filters used tickets" do
      t1 = booking.tickets.create!(status: :active)
      t2 = booking.tickets.create!(status: :used)
      expect(Ticket.used).to contain_exactly(t2)
    end
  end

  describe "associations" do
    it "belongs to a booking" do
      ticket = booking.tickets.create!
      expect(ticket.booking).to eq(booking)
    end

    it "destroys tickets when booking is destroyed" do
      booking.tickets.create!
      expect { booking.destroy }.to change(Ticket, :count).by(-1)
    end
  end
end
