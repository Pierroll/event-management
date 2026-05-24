class EventImage < ApplicationRecord
  # =========================
  # RELATIONS
  # =========================
  belongs_to :event

  # =========================
  # VALIDATIONS
  # =========================
  validates :url,
            presence: true

  # =========================
  # DEFAULTS
  # =========================
  attribute :display_order,
            :integer,
            default: 0

  # =========================
  # ORDER
  # =========================
  default_scope {
    order(display_order: :asc)
  }
end