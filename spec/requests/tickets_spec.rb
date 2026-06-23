# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Tickets", type: :request do
  let(:category) { Category.create!(name: "Test Tickets", slug: "test-req-tickets") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.tickets@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.tickets@test.com", password: "password123", confirmed_at: Time.current) }
  let(:other_user) { User.create!(name: "Other User", email: "other.tickets@test.com", password: "password123", confirmed_at: Time.current) }

  let(:event) do
    e = Event.new(
      name: "Evento Tickets",
      description: "Test event for tickets.",
      city: "Lima",
      address: "Av. Test",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/t.jpg")
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
      status: :confirmed,
      booked_at: Time.current
    )
  end

  let(:ticket) { Ticket.create!(booking: booking, attendee_name: "Original Name", status: :active) }

  describe "PATCH /tickets/:id" do
    context "when user is not signed in" do
      it "redirects to the login page" do
        patch ticket_path(ticket), params: { ticket: { attendee_name: "New Name" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is signed in and owns the ticket" do
      before { sign_in user }

      it "updates the attendee name and redirects to the booking details" do
        patch ticket_path(ticket), params: { ticket: { attendee_name: "New Name" } }
        expect(response).to redirect_to(booking_path(booking))
        expect(flash[:notice]).to eq("El nombre del asistente fue actualizado con éxito.")
        expect(ticket.reload.attendee_name).to eq("New Name")
      end
    end

    context "when user tries to update another user's ticket" do
      before { sign_in other_user }

      it "denies access and redirects with an alert" do
        patch ticket_path(ticket), params: { ticket: { attendee_name: "Hack Name" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("No estás autorizado")
        expect(ticket.reload.attendee_name).to eq("Original Name")
      end
    end
  end
end
