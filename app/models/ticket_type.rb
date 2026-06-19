# frozen_string_literal: true

class TicketType < ApplicationRecord
  # ── Relations ──
  belongs_to :event
  has_many :bookings, dependent: :restrict_with_error

  # ── Validations ──
  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_total, numericality: { only_integer: true, greater_than: 0 }

  # ── Scopes ──
  scope :on_sale, lambda {
    now = Time.current
    where(
      '(sales_start_at IS NULL OR sales_start_at <= :now) AND (sales_end_at IS NULL OR sales_end_at >= :now)',
      now: now
    )
  }

  scope :ordered, -> { order(:position) }

  # ── Methods ──
  def remaining_capacity
    quantity_total - bookings.occupying_capacity.sum(:quantity)
  end

  def sold_out?
    remaining_capacity <= 0
  end

  def on_sale?
    return false if sales_start_at.present? && sales_start_at > Time.current
    return false if sales_end_at.present? && sales_end_at < Time.current

    true
  end

  # available? = dentro de ventana de venta (sales_start/end_at) Y
  # no agotado (no considera si el Event padre está publicado)
  def available?
    on_sale? && !sold_out?
  end

  # Máxima cantidad comprable en este momento, considerando
  # remaining_capacity y el límite por orden (max_per_order).
  def max_purchasable_now
    return 0 unless available?

    max_per_order.present? ? [max_per_order, remaining_capacity].min : remaining_capacity
  end
end
