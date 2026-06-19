# frozen_string_literal: true

# Authorization policy for check-in actions (Organizer::CheckInsController).
# Authorizes against the Event record — the organizer must own the event
# (or be admin) to perform check-ins.
class CheckInPolicy < ApplicationPolicy
  def show?
    user.present? && (user.admin? || user.organizer?)
  end

  def create?
    user.present? && (user.admin? || (user.organizer? && record.organizer == user))
  end
end
