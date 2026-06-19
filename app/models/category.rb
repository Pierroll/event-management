class Category < ApplicationRecord
  # =========================
  # RELATIONS
  # =========================
  has_many :events,
           dependent: :restrict_with_error

  # =========================
  # VALIDATIONS
  # =========================
  validates :name,
            presence: true,
            uniqueness: true

  validates :slug,
            presence: true,
            uniqueness: true

  # =========================
  # DEFAULTS
  # =========================
  attribute :active, :boolean, default: true

  # =========================
  # SCOPES
  # =========================
  # NOTE: this is deliberately distinct from Booking.occupying_capacity and
  # Ticket.active — "active" here means the boolean column, not a status combination.
  scope :active, -> { where(active: true) }
end