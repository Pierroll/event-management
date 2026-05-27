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
  validates :name, presence: true
  validate :must_have_at_least_one_image

  # Validaciones estrictas solo cuando se intenta publicar
  with_options if: :published? do |event|
    event.validates :description, presence: true, length: { minimum: 20 }
    event.validates :city, presence: true
    event.validates :address, presence: true
    event.validates :start_date, presence: true
    event.validates :category_id, presence: true
  end

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
  attr_accessor :primary_image_param

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
  # METHODS
  # =========================
  def primary_image
    event_images.first
  end

  def secondary_images
    event_images.offset(1)
  end

  private

  def must_have_at_least_one_image
    has_images = event_images.reject(&:marked_for_destruction?).any? ||
                 (respond_to?(:images) && images.present?) ||
                 primary_image_param.present?

    unless has_images
      errors.add(:base, "Debes subir al menos una imagen para registrar el evento")
    end
  end

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
