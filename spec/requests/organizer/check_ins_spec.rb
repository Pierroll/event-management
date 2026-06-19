# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Organizer::CheckIns", type: :request do
  let(:category) { Category.create!(name: "Test", slug: "test-chk") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.chk@test.com", password: "password123", confirmed_at: Time.current).tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:other_organizer) do
    User.create!(name: "Other", email: "other.chk@test.com", password: "password123", confirmed_at: Time.current).tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.chk@test.com", password: "password123", confirmed_at: Time.current) }
  let(:admin) do
    User.create!(name: "Admin", email: "admin.chk@test.com", password: "password123", confirmed_at: Time.current).tap do |u|
      u.roles << Role.find_or_create_by!(name: "admin")
    end
  end
  let(:event) do
    e = Event.new(
      name: "Evento Check-in",
      description: "Test event for check-in.",
      city: "Lima", address: "Av. Test",
      start_date: 1.day.from_now, end_date: 1.day.from_now + 2.hours,
      currency: "PEN", category: category, organizer: organizer, status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/chk.jpg")
    e.ticket_types.build(name: "General", price: 50, quantity_total: 100)
    e.save!
    e
  end
  let(:other_event) do
    e = Event.new(
      name: "Otro Evento",
      description: "Another event for cross-event check-in test.",
      city: "Lima", address: "Av. Other",
      start_date: 1.day.from_now, end_date: 1.day.from_now + 2.hours,
      currency: "PEN", category: category, organizer: organizer, status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/oth.jpg")
    e.ticket_types.build(name: "General", price: 30, quantity_total: 50)
    e.save!
    e
  end
  let(:ticket_type) { event.ticket_types.first }
  let(:booking) do
    Booking.create!(
      user: user, event: event, ticket_type: ticket_type,
      quantity: 1, unit_price: ticket_type.price, status: :confirmed
    )
  end
  let!(:ticket) { booking.tickets.create!(status: :active) }

  describe "GET /organizer/events/:event_id/check_in" do
    context "when authenticated as organizer" do
      before { sign_in organizer }

      it "returns 200" do
        get organizer_event_check_in_path(event)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        get organizer_event_check_in_path(event)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as regular user" do
      before { sign_in user }

      it "redirects with alert" do
        get organizer_event_check_in_path(event)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /organizer/events/:event_id/check_in" do
    context "when authenticated as organizer" do
      before { sign_in organizer }

      it "marks a valid ticket as used" do
        expect {
          post organizer_event_check_in_path(event),
               params: { qr_code: ticket.qr_code }.to_json,
               headers: { "CONTENT_TYPE" => "application/json" }
        }.to change { ticket.reload.status }.from("active").to("used")
      end

      it "sets checked_in_at timestamp" do
        post organizer_event_check_in_path(event),
             params: { qr_code: ticket.qr_code }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }
        expect(ticket.reload.checked_in_at).to be_present
      end

      it "returns success JSON" do
        post organizer_event_check_in_path(event),
             params: { qr_code: ticket.qr_code }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["success"]).to be true
      end

      context "with already used ticket" do
        before { ticket.update!(status: :used, checked_in_at: Time.current) }

        it "returns conflict" do
          post organizer_event_check_in_path(event),
               params: { qr_code: ticket.qr_code }.to_json,
               headers: { "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:conflict)
          expect(response.parsed_body["error"]).to eq("Este ticket ya fue usado")
        end
      end

      context "with unknown qr_code" do
        it "returns not_found" do
          post organizer_event_check_in_path(event),
               params: { qr_code: "non_existent_qr" }.to_json,
               headers: { "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:not_found)
          expect(response.parsed_body["error"]).to eq("Ticket no encontrado")
        end
      end

      context "with ticket from another event" do
        let(:other_booking) do
          Booking.create!(
            user: user, event: other_event, ticket_type: other_event.ticket_types.first,
            quantity: 1, unit_price: 30, status: :confirmed
          )
        end
        let!(:other_ticket) { other_booking.tickets.create!(status: :active) }

        it "returns forbidden" do
          post organizer_event_check_in_path(event),
               params: { qr_code: other_ticket.qr_code }.to_json,
               headers: { "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:forbidden)
          expect(response.parsed_body["error"]).to eq("Este ticket no pertenece a este evento")
        end
      end

      context "when event belongs to another organizer" do
        let(:other_org_event) do
          e = Event.new(
            name: "Evento Ajeno",
            description: "Event for other organizer check-in test.",
            city: "Lima", address: "Av. Other",
            start_date: 1.day.from_now, end_date: 1.day.from_now + 2.hours,
            currency: "PEN", category: category, organizer: other_organizer, status: :published
          )
          e.event_images.build(display_order: 0, image: "https://example.com/ajeno.jpg")
          e.ticket_types.build(name: "General", price: 40, quantity_total: 50)
          e.save!
          e
        end

        it "returns not_found (scoped to own events)" do
          post organizer_event_check_in_path(other_org_event),
               params: { qr_code: "any_code" }.to_json,
               headers: { "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when authenticated as admin" do
      before { sign_in admin }

      it "can check-in any event's ticket" do
        post organizer_event_check_in_path(event),
             params: { qr_code: ticket.qr_code }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }
        expect(response).to have_http_status(:ok)
        expect(ticket.reload).to be_used
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        post organizer_event_check_in_path(event),
             params: { qr_code: ticket.qr_code }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
