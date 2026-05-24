class Event < ApplicationRecord
  # =========================
  # ENUMS
  # =========================
  enum :status, {
    draft: 0,
    published: 1,
    canceled: 2,
    finished: 3
  }

  # =========================
  # RELATIONS
  # =========================
  belongs_to :organizer,
             class_name: 'User'

  belongs_to :category

  has_many :event_images,
           dependent: :destroy

  has_many :comments,
           dependent: :destroy

  # =========================
  # VALIDATIONS
  # =========================
  validates :name,
            presence: true

  validates :description,
            presence: true

  validates :city,
            presence: true

  validates :address,
            presence: true

  validates :start_date,
            presence: true

  validates :price,
            numericality: {
              greater_than_or_equal_to: 0
            }

  validates :average_rating,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 5
            }

  validate :end_date_after_start_date

  # =========================
  # DEFAULTS
  # =========================
  attribute :price, :decimal, default: 0
  attribute :average_rating, :decimal, default: 0

  # =========================
  # SCOPES
  # =========================
  scope :published_only, -> {
    where(status: :published)
  }

  scope :upcoming, -> {
    published_only.where('start_date > ?', Time.current)
  }

  scope :by_city, ->(city) {
    where(city: city)
  }

  scope :by_category, ->(category_id) {
    where(category_id: category_id)
  }

  # =========================
  # CUSTOM VALIDATIONS
  # =========================
  private

  def end_date_after_start_date
    return if end_date.blank?
    return if start_date.blank?

    if end_date <= start_date
      errors.add(
        :end_date,
        'must be after start date'
      )
    end
  end
end