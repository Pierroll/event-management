class User < ApplicationRecord
  # =========================
  # DEVISE
  # =========================
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

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

  has_many :bookings, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_events, through: :favorites, source: :event

  # =========================
  # VALIDATIONS
  # =========================
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  # =========================
  # DEFAULTS
  # =========================
  attribute :active, :boolean, default: true
  attr_accessor :selected_role

  after_create :assign_selected_role

  # =========================
  # OAUTH & CONFIRMATION
  # =========================
  def self.from_google(auth, role_name: nil)
    user = find_by(email: auth.info.email)

    if user
      user.update!(provider: auth.provider, uid: auth.uid)
    else
      user = new(
        email: auth.info.email,
        name: auth.info.name,
        password: SecureRandom.hex(32),
        provider: auth.provider,
        uid: auth.uid,
        confirmed_at: Time.current
      )
      user.selected_role = role_name
      user.save!
    end

    user
  end

  def confirmed?
    confirmed_at.present? || provider.present?
  end

  def confirm_with_code(code)
    ConfirmationCodeService.verify(self, code)
  end

  def generate_confirmation_code
    ConfirmationCodeService.generate(self)
  end

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

  private

  def assign_selected_role
    role = Role.find_by(name: selected_role.presence || "registered_user")
    user_roles.create(role: role) if role
  end
end