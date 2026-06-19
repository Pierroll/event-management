# frozen_string_literal: true

class PaymentPolicy < ApplicationPolicy
  def show?
    user.present? && (user.admin? || record.booking.user_id == user.id)
  end

  def create?
    user.present? &&
      (user.admin? || record.booking.user_id == user.id) &&
      record.booking.pending?
  end

  def new?
    create?
  end
end
