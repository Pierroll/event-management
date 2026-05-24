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
  scope :active, -> { where(active: true) }
end