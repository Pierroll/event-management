class CategoryPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.active? || (user.present? && user.admin?)
  end

  def create?
    user.present? && user.admin?
  end

  def update?
    user.present? && user.admin?
  end

  def destroy?
    user.present? && user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.present? && user.admin?
        scope.all
      else
        scope.active
      end
    end
  end
end
