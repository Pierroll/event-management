class BookingPolicy < ApplicationPolicy
  def index?
    user.present? && !user.organizer?
  end

  def show?
    user.present? && (user.admin? || record.user_id == user.id)
  end

  def create?
    user.present?
  end

  def new?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
