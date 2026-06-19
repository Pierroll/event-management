# frozen_string_literal: true

module Webhooks
  class PaymentsController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :require_email_confirmation
    before_action :verify_webhook_signature

    # POST /webhooks/payments/receive
    # Generic webhook endpoint for payment provider callbacks.
    # Expects JSON body with at least:
    #   { provider_charge_id: "ch_xxx", status: "approved"|"declined"|"refunded" }
    #
    # Ignores out-of-order events (e.g. "approved" arriving after "refunded")
    # to prevent payment state corruption.
    #
    # Security: validates X-Webhook-Secret header against ENV["WEBHOOK_SHARED_SECRET"]
    # using ActiveSupport::SecurityUtils.secure_compare to prevent timing attacks.
    #
    # ponytail: shared-secret is a TEMPORARY measure until Culqi's official
    # webhook signing mechanism is documented. When Culqi credentials are
    # obtained in production, replace this with the real HMAC/header verification.
    def receive
      payload = JSON.parse(request.body.read)

      payment = Payment.find_by(provider_charge_id: payload["provider_charge_id"])

      if payment
        new_status = payload["status"]

        if payment.can_transition_to?(new_status)
          payment.update!(status: new_status, raw_response: payload)
          payment.booking.update!(status: :expired) if payment.declined? && payment.booking.pending?
        else
          Rails.logger.warn "[Webhook] Ignored invalid transition #{payment.status} -> #{new_status} " \
                            "for #{payment.provider_charge_id}"
        end

        head :ok
      else
        Rails.logger.warn "[Webhook] Unknown provider_charge_id: #{payload['provider_charge_id']}"
        head :ok
      end
    rescue JSON::ParserError => e
      Rails.logger.error "[Webhook] Invalid JSON: #{e.message}"
      head :bad_request
    end

    private

    def verify_webhook_signature
      secret = ENV["WEBHOOK_SHARED_SECRET"]
      return if secret.blank?

      provided = request.headers["X-Webhook-Secret"]

      unless provided.present? && ActiveSupport::SecurityUtils.secure_compare(secret, provided)
        Rails.logger.warn "[Webhook] Invalid signature from #{request.remote_ip}"
        head :unauthorized
      end
    end
  end
end
