# frozen_string_literal: true

class Ticket < ApplicationRecord
  # ── Relations ──
  belongs_to :booking

  # ── Enums ──
  # active    → puede hacer check-in
  # used      → ya ingresó al evento
  # canceled  → cancelado
  enum :status, {
    active: 0,
    used: 1,
    canceled: 2
  }

  # ── Validations ──
  validates :qr_code, presence: true, uniqueness: true

  # ── Scopes ──
  scope :active, -> { where(status: :active) }
  scope :used,  -> { where(status: :used) }

  # ── Check-in ──
  def check_in!
    return false unless active?

    Ticket.where(id: id, status: :active)
          .update_all(status: :used, checked_in_at: Time.current) == 1
  end

  # ── Callbacks ──
  before_validation :generate_qr_code, on: :create

  private

  def generate_qr_code
    self.qr_code ||= SecureRandom.uuid
  end
end
