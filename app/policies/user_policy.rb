class UserPolicy < ApplicationPolicy
  def index?
    user.present? && user.admin?
  end

  def show?
    user.present? && (user.admin? || record.id == user.id)
  end

  def create?
    user.present? && user.admin?
  end

  def update?
    user.present? && (user.admin? || record.id == user.id)
  end

  def destroy?
    user.present? && user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.present?
        if user.admin?
          scope.all
        else
          scope.where(id: user.id)
        end
      else
        scope.none
      end
    end
  end
end
