class EventPolicy < ApplicationPolicy
  def index?
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
    user.present? && (user.admin? || record.organizer_id == user.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.nil?
        scope.published_only
      elsif user.admin?
        scope.all
      elsif user.organizer?
        scope.published_only.or(scope.where(organizer_id: user.id))
      else
        scope.published_only
      end
    end
  end
end
