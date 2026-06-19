# frozen_string_literal: true

class TicketPolicy < ApplicationPolicy
  def show?
    user.admin? || record.booking.user_id == user.id
  end

  # Check-in is handled by Organizer::BaseController, not Pundit
end
