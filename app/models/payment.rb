# frozen_string_literal: true

class Payment < ApplicationRecord
  # ── Relations ──
  belongs_to :booking

  # ── Enums ──
  enum :status, {
    pending: 0,
    approved: 1,
    declined: 2,
    refunded: 3
  }

  # ── State Machine ──
  # Prevents out-of-order webhook events from corrupting payment state.
  ALLOWED_TRANSITIONS = {
    pending:  %i[approved declined],
    approved: %i[declined refunded],
    declined: %i[],
    refunded: %i[]
  }.freeze

  def can_transition_to?(new_status)
    new_status = new_status.to_sym if new_status.is_a?(String)
    return false unless ALLOWED_TRANSITIONS.key?(new_status)

    current = status&.to_sym || :pending
    ALLOWED_TRANSITIONS.fetch(current, []).include?(new_status)
  end

  # ── Validations ──
  validates :provider, presence: true
  validates :provider_charge_id, uniqueness: { allow_nil: true }
  validates :booking, uniqueness: { message: "ya tiene un pago registrado" }
end
