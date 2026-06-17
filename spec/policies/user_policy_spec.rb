require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:admin) do
    User.create!(name: "Admin", email: "admin@test.com", password: "password123", active: true).tap do |u|
      u.roles << Role.find_or_create_by!(name: "admin")
    end
  end
  let(:user) { User.create!(name: "User", email: "user@test.com", password: "password123", active: true) }
  let(:other_user) { User.create!(name: "Other", email: "other@test.com", password: "password123", active: true) }
  let(:guest) { nil }

  permissions :index? do
    it "allows admin" do
      expect(subject).to permit(admin, User)
    end

    it "denies regular users" do
      expect(subject).not_to permit(user, User)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, User)
    end
  end

  permissions :show? do
    it "allows admin to see any user" do
      expect(subject).to permit(admin, user)
    end

    it "allows user to see their own profile" do
      expect(subject).to permit(user, user)
    end

    it "denies user from seeing another user's profile" do
      expect(subject).not_to permit(user, other_user)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, user)
    end
  end

  permissions :update? do
    it "allows admin to update any user" do
      expect(subject).to permit(admin, user)
    end

    it "allows user to update their own profile" do
      expect(subject).to permit(user, user)
    end

    it "denies user from updating another user" do
      expect(subject).not_to permit(user, other_user)
    end
  end

  describe "scope" do
    let!(:user_a) { User.create!(name: "A", email: "a@test.com", password: "password123") }
    let!(:user_b) { User.create!(name: "B", email: "b@test.com", password: "password123") }

    it "shows all users to admin" do
      scope = UserPolicy::Scope.new(admin, User.all).resolve
      expect(scope).to include(user_a, user_b)
    end

    it "shows only self to regular user" do
      scope = UserPolicy::Scope.new(user_a, User.all).resolve
      expect(scope).to contain_exactly(user_a)
    end

    it "returns none for guest" do
      scope = UserPolicy::Scope.new(nil, User.all).resolve
      expect(scope).to be_empty
    end
  end
end
