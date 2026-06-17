class EventImage < ApplicationRecord
  # =========================
  # RELATIONS
  # =========================
  belongs_to :event
  has_one_attached :file

  # =========================
  # VALIDATIONS
  # =========================
  validate :image_or_file_present

  # =========================
  # DEFAULTS
  # =========================
  attribute :display_order,
            :integer,
            default: 0

  # =========================
  # SCOPES
  # =========================
  scope :ordered, -> { order(display_order: :asc) }

  # =========================
  # METHODS
  # =========================
  def image_url
    if file.attached?
      Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
    else
      image
    end
  end

  private

  def image_or_file_present
    if image.blank? && !file.attached?
      errors.add(:base, :image_or_file_required)
    end
  end
end