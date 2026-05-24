class Role < ApplicationRecord
  # =========================
  # RELATIONS
  # =========================
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  # =========================
  # VALIDATIONS
  # =========================
  validates :name,
            presence: true,
            uniqueness: true
end