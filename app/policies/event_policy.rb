class EventPolicy < ApplicationPolicy
  def index?
    true
  end

  def create_alert?
    true
  end

  def show?
    record.published? || (user.present? && (user.admin? || record.organizer_id == user.id))
  end

  def create?
    user.present? && (user.admin? || user.organizer?)
  end

  def update?
    user.present? && (user.admin? || record.organizer_id == user.id)
  end

  def destroy?
    user.present? && (user.admin? || record.organizer_id == user.id) && record.draft? && record.bookings.none?
  end

  def cancel?
    user.present? && (user.admin? || record.organizer_id == user.id) && record.published?
  end

  def attendees?
    user.present? && (user.admin? || record.organizer_id == user.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.nil?
        scope.published
      elsif user.admin?
        scope.all
      elsif user.organizer?
        scope.published.or(scope.where(organizer_id: user.id))
      else
        scope.published
      end
    end
  end
end
