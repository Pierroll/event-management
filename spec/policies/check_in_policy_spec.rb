# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckInPolicy, type: :policy do
  subject { described_class }

  let(:user) { User.create!(name: "User", email: "user@test.com", password: "password123", confirmed_at: Time.current) }
  let(:organizer) do
    User.create!(name: "Org", email: "org@test.com", password: "password123", confirmed_at: Time.current).tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:other_organizer) do
    User.create!(name: "OtherOrg", email: "otherorg@test.com", password: "password123", confirmed_at: Time.current).tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:admin) do
    User.create!(name: "Admin", email: "admin@test.com", password: "password123", confirmed_at: Time.current).tap do |u|
      u.roles << Role.find_or_create_by!(name: "admin")
    end
  end
  let(:guest) { nil }
  let(:event) { instance_double("Event", organizer: organizer) }

  permissions :show? do
    it "allows admin" do
      expect(subject).to permit(admin, event)
    end

    it "allows an organizer" do
      expect(subject).to permit(organizer, event)
    end

    it "denies regular users" do
      expect(subject).not_to permit(user, event)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, event)
    end
  end

  permissions :create? do
    it "allows admin on any event" do
      expect(subject).to permit(admin, event)
    end

    it "allows the event's organizer" do
      expect(subject).to permit(organizer, event)
    end

    it "denies another organizer who doesn't own the event" do
      expect(subject).not_to permit(other_organizer, event)
    end

    it "denies regular users" do
      expect(subject).not_to permit(user, event)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, event)
    end
  end
end
