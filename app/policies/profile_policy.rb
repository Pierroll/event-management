# frozen_string_literal: true

class ProfilePolicy < ApplicationPolicy
  def show?
    user.present? && (user.admin? || record == user)
  end

  def update?
    record == user
  end

  def edit?
    update?
  end
end
