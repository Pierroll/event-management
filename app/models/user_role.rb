class UserRole < ApplicationRecord
  # =========================
  # RELATIONS
  # =========================
  belongs_to :user
  belongs_to :role

  belongs_to :assigned_by,
             class_name: 'User',
             optional: true

  # =========================
  # VALIDATIONS
  # =========================
  validates :user_id,
            uniqueness: {
              scope: :role_id
            }
end