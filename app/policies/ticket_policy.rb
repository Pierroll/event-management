# frozen_string_literal: true

class TicketPolicy < ApplicationPolicy
  def show?
    user.present? && (user.admin? || record.booking.user_id == user.id)
  end

  def update?
    user.present? && (user.admin? || (record.booking.confirmed? && record.booking.user_id == user.id && record.active?))
  end

  # Check-in is handled by Organizer::BaseController, not Pundit
end
