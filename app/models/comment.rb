class Comment < ApplicationRecord
  # =========================
  # RELATIONS
  # =========================
  belongs_to :event
  belongs_to :user

  # =========================
  # VALIDATIONS
  # =========================
  validates :content,
            presence: true,
            length: {
              minimum: 10,
              maximum: 1000
            }

  validates :rating,
            inclusion: {
              in: 1..5
            }

  validates :user_id,
            uniqueness: {
              scope: :event_id,
              message: 'already commented on this event'
            }

  # =========================
  # CALLBACKS
  # =========================
  after_save :update_event_rating
  after_destroy :update_event_rating

  # =========================
  # METHODS
  # =========================
  private

  def update_event_rating
    avg = event.comments.average(:rating).to_f.round(2)

    event.update_column(
      :average_rating,
      avg
    )
  end
end