require 'rails_helper'

RSpec.describe CategoryPolicy, type: :policy do
  subject { described_class }

  let(:admin) do
    User.create!(name: "Admin", email: "admin@test.com", password: "password123", active: true).tap do |u|
      u.roles << Role.find_or_create_by!(name: "admin")
    end
  end
  let(:user) { User.create!(name: "User", email: "user@test.com", password: "password123", active: true) }
  let(:guest) { nil }

  let(:active_category) { Category.new(name: "Active", slug: "active", active: true) }
  let(:inactive_category) { Category.new(name: "Inactive", slug: "inactive", active: false) }

  permissions :index? do
    it "allows guests" do
      expect(subject).to permit(guest, Category)
    end

    it "allows any user" do
      expect(subject).to permit(user, Category)
    end
  end

  permissions :show? do
    it "allows guests to see active categories" do
      expect(subject).to permit(guest, active_category)
    end

    it "denies guests from seeing inactive categories" do
      expect(subject).not_to permit(guest, inactive_category)
    end

    it "allows admin to see any category" do
      expect(subject).to permit(admin, inactive_category)
    end
  end

  permissions :create? do
    it "allows admin" do
      expect(subject).to permit(admin, Category.new)
    end

    it "denies regular users" do
      expect(subject).not_to permit(user, Category.new)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, Category.new)
    end
  end

  permissions :update? do
    it "allows admin" do
      expect(subject).to permit(admin, active_category)
    end

    it "denies regular users" do
      expect(subject).not_to permit(user, active_category)
    end
  end

  permissions :destroy? do
    it "allows admin" do
      expect(subject).to permit(admin, active_category)
    end

    it "denies regular users" do
      expect(subject).not_to permit(user, active_category)
    end
  end

  describe "scope" do
    let!(:cat_active) { Category.create!(name: "Active", slug: "active-1", active: true) }
    let!(:cat_inactive) { Category.create!(name: "Inactive", slug: "inactive-1", active: false) }

    it "shows only active categories to regular users" do
      scope = CategoryPolicy::Scope.new(user, Category.all).resolve
      expect(scope).to include(cat_active)
      expect(scope).not_to include(cat_inactive)
    end

    it "shows all categories to admin" do
      scope = CategoryPolicy::Scope.new(admin, Category.all).resolve
      expect(scope).to include(cat_active, cat_inactive)
    end
  end
end
