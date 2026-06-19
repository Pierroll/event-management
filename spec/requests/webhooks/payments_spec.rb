require 'rails_helper'

RSpec.describe "Webhooks::Payments", type: :request do
  let(:category) { Category.create!(name: "Test", slug: "test-wh") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.wh@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user.wh@test.com", password: "password123", confirmed_at: Time.current) }
  let(:event) do
    e = Event.new(
      name: "Evento Webhook",
      description: "Test event for webhook specs.",
      city: "Lima",
      address: "Av. Test",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    )
    e.event_images.build(display_order: 0, image: "https://example.com/wh.jpg")
    e.ticket_types.build(name: "General", price: 50, quantity_total: 100)
    e.save!
    e
  end
  let(:ticket_type) { event.ticket_types.first }
  let(:booking) do
    Booking.create!(
      user: user, event: event, ticket_type: ticket_type,
      quantity: 1, unit_price: 50, status: :pending, expires_at: 15.minutes.from_now
    )
  end
  let!(:payment) do
    Payment.create!(
      booking: booking, provider: "mock",
      status: :approved, provider_charge_id: "ch_webhook_123"
    )
  end

  describe "POST /webhooks/payments/receive" do
    context "with WEBHOOK_SHARED_SECRET configured" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("WEBHOOK_SHARED_SECRET").and_return("s3cr3t")
      end

      it "returns 401 when no X-Webhook-Secret header is sent" do
        post receive_webhooks_payments_path,
             params: { provider_charge_id: "ch_webhook_123", status: "refunded" }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
        expect(payment.reload).to be_approved
      end

      it "returns 401 when X-Webhook-Secret is wrong" do
        post receive_webhooks_payments_path,
             params: { provider_charge_id: "ch_webhook_123", status: "refunded" }.to_json,
             headers: { "CONTENT_TYPE" => "application/json", "X-Webhook-Secret" => "wrong_secret" }

        expect(response).to have_http_status(:unauthorized)
        expect(payment.reload).to be_approved
      end

      it "returns 401 on timing-attempt difference" do
        post receive_webhooks_payments_path,
             params: { provider_charge_id: "ch_webhook_123", status: "refunded" }.to_json,
             headers: { "CONTENT_TYPE" => "application/json", "X-Webhook-Secret" => "S3CR3T" }

        expect(response).to have_http_status(:unauthorized)
      end

      it "processes normally with correct secret" do
        post receive_webhooks_payments_path,
             params: { provider_charge_id: "ch_webhook_123", status: "refunded" }.to_json,
             headers: { "CONTENT_TYPE" => "application/json", "X-Webhook-Secret" => "s3cr3t" }

        expect(response).to have_http_status(:ok)
        expect(payment.reload).to be_refunded
      end
    end

    context "without WEBHOOK_SHARED_SECRET (no ENV set)" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("WEBHOOK_SHARED_SECRET").and_return(nil)
      end

      it "updates payment status to refunded" do
        post receive_webhooks_payments_path,
             params: { provider_charge_id: "ch_webhook_123", status: "refunded" }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
        expect(payment.reload).to be_refunded
      end

      it "updates payment status to declined and expires booking" do
        post receive_webhooks_payments_path,
             params: { provider_charge_id: "ch_webhook_123", status: "declined" }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
        expect(payment.reload).to be_declined
        expect(booking.reload).to be_expired
      end

      it "accepts unknown charges gracefully" do
        post receive_webhooks_payments_path,
             params: { provider_charge_id: "ch_unknown", status: "approved" }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
      end

      it "returns bad_request for invalid JSON" do
        post receive_webhooks_payments_path,
             params: "not json",
             headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:bad_request)
      end

      it "does not require authentication" do
        post receive_webhooks_payments_path,
             params: { provider_charge_id: "ch_webhook_123", status: "refunded" }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
      end

      context "out-of-order events" do
        let!(:payment) do
          Payment.create!(
            booking: booking, provider: "mock",
            status: :refunded, provider_charge_id: "ch_out_of_order"
          )
        end

        it "ignores approved after refunded" do
          post receive_webhooks_payments_path,
               params: { provider_charge_id: "ch_out_of_order", status: "approved" }.to_json,
               headers: { "CONTENT_TYPE" => "application/json" }

          expect(payment.reload).to be_refunded
        end

        it "ignores declined after refunded" do
          post receive_webhooks_payments_path,
               params: { provider_charge_id: "ch_out_of_order", status: "declined" }.to_json,
               headers: { "CONTENT_TYPE" => "application/json" }

          expect(payment.reload).to be_refunded
        end

        it "ignores approved after declined" do
          payment.update!(status: :declined)

          post receive_webhooks_payments_path,
               params: { provider_charge_id: "ch_out_of_order", status: "approved" }.to_json,
               headers: { "CONTENT_TYPE" => "application/json" }

          expect(payment.reload).to be_declined
        end

        it "still returns 200 so provider stops retrying" do
          post receive_webhooks_payments_path,
               params: { provider_charge_id: "ch_out_of_order", status: "approved" }.to_json,
               headers: { "CONTENT_TYPE" => "application/json" }

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
