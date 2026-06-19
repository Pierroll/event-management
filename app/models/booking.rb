# frozen_string_literal: true

class Booking < ApplicationRecord
  # ── Enums ──
  # pending   → esperando pago
  # confirmed → pagado / confirmado
  # canceled  → cancelado por usuario o sistema
  # expired   → expiró antes de pagar
  enum :status, {
    pending: 0,
    confirmed: 1,
    canceled: 2,
    expired: 3
  }

  # ── Relations ──
  belongs_to :user
  belongs_to :event
  belongs_to :ticket_type
  has_one :payment, dependent: :destroy
  has_many :tickets, dependent: :destroy

  # ── Validations ──
  validates :quantity, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }

  validate :quantity_within_max_per_order

  # ── Scopes ──
  # Bookings that occupy event capacity (confirmed + pending).
  # Canceled and expired bookings don't reduce available capacity.
  scope :occupying_capacity, -> { where(status: [:confirmed, :pending]) }
  scope :for_event, ->(event_id) { where(event_id: event_id) }

  # ── Callbacks ──
  before_create :set_booked_at
  before_create :set_expiration, if: :pending?

  # ── Methods ──
  def total_price
    unit_price * quantity
  end

  def expired_unpaid?
    pending? && expires_at.present? && expires_at < Time.current
  end

  private

  def set_booked_at
    self.booked_at = Time.current
  end

  def set_expiration
    self.expires_at ||= 15.minutes.from_now
  end

  def quantity_within_max_per_order
    return unless ticket_type.max_per_order.present?
    return if quantity <= ticket_type.max_per_order

    errors.add(:quantity, :exceeds_max_per_order,
               max: ticket_type.max_per_order,
               ticket_type: ticket_type.name)
  end
end
