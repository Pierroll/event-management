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
  # GEOCODING
  # =========================
  geocoded_by :address
  after_validation :geocode, if: ->(obj) { obj.address.present? && obj.address_changed? && obj.latitude.blank? && obj.longitude.blank? }

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

  has_many :bookings,
           dependent: :destroy

  has_many :tickets,
           through: :bookings

  has_many :favorites,
           dependent: :destroy

  has_many :favorited_by,
           through: :favorites,
           source: :user

  has_many :ticket_types,
           dependent: :restrict_with_error

  accepts_nested_attributes_for :ticket_types, allow_destroy: true

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

  validates :average_rating,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 5
            }

  validate :end_date_after_start_date

  # =========================
  # DEFAULTS
  # =========================
  attribute :average_rating, :decimal, default: 0
  attr_accessor :primary_image_param

  # =========================
  # SCOPES
  # =========================
  scope :upcoming, -> {
    published.where('start_date > ?', Time.current)
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
    # Use SQL ordering when persisted (loads 1 record), fallback to in-memory for unsaved
    if persisted?
      event_images.order(:display_order).first
    else
      event_images.min_by(&:display_order)
    end
  end

  def secondary_images
    if persisted?
      event_images.order(:display_order).offset(1)
    else
      event_images.sort_by(&:display_order).drop(1)
    end
  end

  # ── Booking / Availability ──
  def remaining_capacity
    if max_capacity.present?
      [max_capacity - bookings.occupying_capacity.sum(:quantity), 0].max
    else
      total_quantity = ticket_types.sum(:quantity_total)
      total_booked = bookings.occupying_capacity.sum(:quantity)
      [total_quantity - total_booked, 0].max
    end
  end

  def sold_out?
    remaining_capacity <= 0
  end

  # available? = publicado Y no agotado (no considera ventana de venta,
  # eso es responsabilidad de TicketType)
  def available?
    published? && !sold_out?
  end

  # ── Pricing ──
  def price_range
    return nil if ticket_types.empty?

    prices = ticket_types.map(&:price)
    min = prices.min
    max = prices.max

    return min if min == max

    min..max
  end

  def finished_more_than_48_hours_ago?
    return false if end_date.blank?
    end_date < 48.hours.ago
  end

  private

  def must_have_at_least_one_image
    return if event_images.reject(&:marked_for_destruction?).any? ||
              primary_image_param.present?

    errors.add(:base, :no_images)
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date <= start_date
      errors.add(:end_date, :after_start_date)
    end
  end
end
