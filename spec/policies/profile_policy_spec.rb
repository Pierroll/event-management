# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfilePolicy, type: :policy do
  subject { described_class }

  let(:user) { User.create!(name: "User", email: "user@test.com", password: "password123", confirmed_at: Time.current) }
  let(:other_user) { User.create!(name: "Other", email: "other@test.com", password: "password123", confirmed_at: Time.current) }
  let(:admin) do
    User.create!(name: "Admin", email: "admin@test.com", password: "password123", confirmed_at: Time.current).tap do |u|
      u.roles << Role.find_or_create_by!(name: "admin")
    end
  end
  let(:guest) { nil }

  permissions :show? do
    it "allows the profile owner" do
      expect(subject).to permit(user, user)
    end

    it "allows admin" do
      expect(subject).to permit(admin, user)
    end

    it "denies other users" do
      expect(subject).not_to permit(other_user, user)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, user)
    end
  end

  permissions :update? do
    it "allows the profile owner" do
      expect(subject).to permit(user, user)
    end

    it "denies admin (admin edits via Admin::UsersController)" do
      expect(subject).not_to permit(admin, user)
    end

    it "denies other users" do
      expect(subject).not_to permit(other_user, user)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, user)
    end
  end
end
