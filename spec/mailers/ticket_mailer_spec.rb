# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketMailer, type: :mailer do
  let(:category) { Category.create!(name: "Test", slug: "test-tml") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.tml@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.tml@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento Mailer",
      description: "Test event for ticket mailer.",
      city: "Lima", address: "Av. Test",
      start_date: 1.day.from_now, end_date: 1.day.from_now + 2.hours,
      currency: "PEN", category: category, organizer: organizer, status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/tml.jpg")
    e.ticket_types.build(name: "VIP", price: 100, quantity_total: 50)
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

  describe "#purchase_confirmation" do
    let(:mail) { described_class.purchase_confirmation(booking) }

    it "sends to the booking user" do
      expect(mail.to).to eq([user.email])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Compra confirmada — Evento Mailer")
    end

    it "includes the event name" do
      expect(mail.body.encoded).to include("Evento Mailer")
    end

    it "includes the ticket type" do
      expect(mail.body.encoded).to include("VIP")
    end

    it "includes the quantity" do
      expect(mail.body.encoded).to include("2")
    end

    it "includes the total" do
      expect(mail.body.encoded).to include("S/")
    end

    it "includes a link to the booking" do
      expect(mail.body.encoded).to include(booking_url(booking))
    end
  end
end
