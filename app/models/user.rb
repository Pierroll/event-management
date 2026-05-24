class User < ApplicationRecord
  # =========================
  # DEVISE
  # =========================
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable

  # =========================
  # RELATIONS
  # =========================
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_many :organized_events,
           class_name: 'Event',
           foreign_key: 'organizer_id',
           dependent: :restrict_with_error

  has_many :comments, dependent: :destroy

  # =========================
  # VALIDATIONS
  # =========================
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  # =========================
  # DEFAULTS
  # =========================
  attribute :active, :boolean, default: true

  # =========================
  # ROLE HELPERS
  # =========================
  def role?(role_name)
    roles.exists?(name: role_name)
  end

  def admin?
    role?('admin')
  end

  def organizer?
    role?('organizer')
  end

  def registered_user?
    role?('registered_user')
  end
end