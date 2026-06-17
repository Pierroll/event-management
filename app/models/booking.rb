# frozen_string_literal: true

class Booking < ApplicationRecord
  # ── Enums ──
  # pending  → esperando pago (para cuando haya gateway)
  # confirmed → pagado / confirmado (demo: directo)
  # cancelled → cancelado por usuario o sistema
  enum :status, {
    pending: 0,
    confirmed: 1,
    cancelled: 2
  }

  # ── Relations ──
  belongs_to :user
  belongs_to :event

  # ── Validations ──
  validates :quantity, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }

  # ── Scopes ──
  scope :active, -> { where(status: :confirmed) }
  scope :for_event, ->(event_id) { where(event_id: event_id) }
end
