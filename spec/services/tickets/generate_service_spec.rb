# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tickets::GenerateService do
  let(:category) { Category.create!(name: "Test", slug: "test-tgs") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.tgs@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.tgs@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento TGS",
      description: "Test event for ticket generation.",
      city: "Lima", address: "Av. Test",
      start_date: 1.day.from_now, end_date: 1.day.from_now + 2.hours,
      currency: "PEN", category: category, organizer: organizer, status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/tgs.jpg")
    e.ticket_types.build(name: "General", price: 50, quantity_total: 100)
    e.save!
    e
  end
  let(:ticket_type) { event.ticket_types.first }
  let(:booking) do
    Booking.create!(
      user: user, event: event, ticket_type: ticket_type,
      quantity: 3, unit_price: ticket_type.price, status: :confirmed
    )
  end

  describe ".call" do
    it "creates one ticket per quantity" do
      expect {
        described_class.call(booking)
      }.to change(Ticket, :count).by(3)
    end

    it "assigns active status to all tickets" do
      described_class.call(booking)
      expect(booking.tickets.reload).to all(be_active)
    end

    it "assigns a unique qr_code to each ticket" do
      described_class.call(booking)
      codes = booking.tickets.pluck(:qr_code)
      expect(codes.uniq).to eq(codes)
      expect(codes.size).to eq(3)
    end

    it "is idempotent — second call does not create more tickets" do
      described_class.call(booking)
      expect {
        described_class.call(booking)
      }.not_to change(Ticket, :count)
    end

    it "returns the existing tickets on repeated calls" do
      first = described_class.call(booking)
      second = described_class.call(booking)
      expect(second).to match_array(first)
    end

    it "queues a confirmation email" do
      expect {
        described_class.call(booking)
      }.to have_enqueued_mail(TicketMailer, :purchase_confirmation)
    end

    it "does not queue email on idempotent call" do
      described_class.call(booking)
      expect {
        described_class.call(booking)
      }.not_to have_enqueued_mail(TicketMailer, :purchase_confirmation)
    end
  end
end
