require 'rails_helper'

RSpec.describe "Payments", type: :request do
  let(:category) { Category.create!(name: "Test", slug: "test-preq") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.preq@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.preq@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento Payment Req",
      description: "Test event for payment requests.",
      city: "Lima",
      address: "Av. Test",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/preq.jpg")
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
      status: :pending,
      expires_at: 15.minutes.from_now
    )
  end

  before do
    sign_in user
    old_val = ENV["PAYMENT_GATEWAY"]
    ENV["PAYMENT_GATEWAY"] = "MockGateway"
    PaymentGateway.remove_instance_variable(:@instance) if PaymentGateway.instance_variable_defined?(:@instance)
  end

  after do
    ENV["PAYMENT_GATEWAY"] = nil
    PaymentGateway.remove_instance_variable(:@instance) if PaymentGateway.instance_variable_defined?(:@instance)
  end

  describe "GET /bookings/:booking_id/payments/new" do
    it "renders the checkout page" do
      get new_booking_payment_path(booking)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Completar pago")
      expect(response.body).to include(@booking.event.name) if @booking
    end

    context "when booking is expired" do
      before { booking.update!(expires_at: 5.minutes.ago) }

      it "redirects with alert" do
        get new_booking_payment_path(booking)
        expect(response).to redirect_to(booking_path(booking))
        expect(flash[:alert]).to eq("Esta reserva ya expiró.")
      end
    end

    context "when booking is already confirmed" do
      before { booking.update!(status: :confirmed) }

      it "redirects via Pundit (policy denies payment on confirmed bookings)" do
        get new_booking_payment_path(booking)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /bookings/:booking_id/payments" do
    context "with valid token" do
      let(:culqi_token_id) { "4111111111111111" }

      it "processes payment and redirects to booking" do
        post booking_payments_path(booking), params: { culqi_token_id: culqi_token_id }
        expect(response).to redirect_to(booking_path(booking))
        expect(flash[:notice]).to eq("Pago exitoso. Tu reserva está confirmada.")
      end

      it "changes booking status to confirmed" do
        expect {
          post booking_payments_path(booking), params: { culqi_token_id: culqi_token_id }
        }.to change { booking.reload.status }.from("pending").to("confirmed")
      end

      it "creates a payment record" do
        expect {
          post booking_payments_path(booking), params: { culqi_token_id: culqi_token_id }
        }.to change(Payment, :count).by(1)
      end
    end

    context "with invalid token" do
      let(:culqi_token_id) { "4242424242424242" }

      it "redirects back to checkout with alert" do
        post booking_payments_path(booking), params: { culqi_token_id: culqi_token_id }
        expect(response).to redirect_to(new_booking_payment_path(booking))
        expect(flash[:alert]).to eq("El pago fue rechazado. Intentá de nuevo.")
      end

      it "does not confirm the booking" do
        post booking_payments_path(booking), params: { culqi_token_id: culqi_token_id }
        expect(booking.reload).to be_pending
      end
    end

    context "with expired booking" do
      let(:culqi_token_id) { "4111111111111111" }
      before { booking.update!(expires_at: 5.minutes.ago) }

      it "redirects with alert" do
        post booking_payments_path(booking), params: { culqi_token_id: culqi_token_id }
        expect(response).to redirect_to(booking_path(booking))
        expect(flash[:alert]).to eq("La reserva expiró. Realizá una nueva.")
      end
    end

    context "when booking belongs to another user" do
      let(:other_user) { User.create!(name: "Other", email: "other.preq@test.com", password: "password123", confirmed_at: Time.current) }
      before { sign_in other_user }

      it "returns not_found" do
        post booking_payments_path(booking), params: { culqi_token_id: "4111111111111111" }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in" do
        post booking_payments_path(booking), params: { culqi_token_id: "4111111111111111" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
