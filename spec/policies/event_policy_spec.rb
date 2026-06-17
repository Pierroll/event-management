require 'rails_helper'

RSpec.describe EventPolicy, type: :policy do
  subject { described_class }

  let!(:category) { Category.create!(name: "Test", slug: "test", active: true) }
  let!(:admin) do
    User.create!(name: "Admin", email: "admin@test.com", password: "password123", active: true).tap do |u|
      u.roles << Role.find_or_create_by!(name: "admin")
    end
  end
  let!(:organizer) do
    User.create!(name: "Organizer", email: "org@test.com", password: "password123", active: true).tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let!(:other_organizer) do
    User.create!(name: "Other Org", email: "other@test.com", password: "password123", active: true).tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let!(:regular_user) do
    User.create!(name: "User", email: "user@test.com", password: "password123", active: true)
  end
  let(:guest) { nil }

  let!(:published_event) do
    Event.new(
      name: "Published Event",
      description: "A publicly visible event.",
      city: "Lima",
      address: "Av. Test 123",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      price: 0,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    ).tap do |e|
      e.event_images.build(display_order: 0, image: "https://example.com/pub.jpg")
      e.save!
    end
  end

  let!(:draft_event) do
    Event.new(
      name: "Draft Event",
      description: "Not yet visible.",
      city: "Lima",
      address: "Av. Draft 456",
      start_date: 2.days.from_now,
      end_date: 2.days.from_now + 2.hours,
      price: 10,
      currency: "PEN",
      category: category,
      organizer: other_organizer,
      status: :draft
    ).tap do |e|
      e.event_images.build(display_order: 0, image: "https://example.com/draft.jpg")
      e.save!
    end
  end

  permissions :show? do
    it "allows guests to see published events" do
      expect(subject).to permit(guest, published_event)
    end

    it "denies guests from seeing draft events" do
      expect(subject).not_to permit(guest, draft_event)
    end

    it "allows regular users to see published events" do
      expect(subject).to permit(regular_user, published_event)
    end

    it "denies regular users from seeing draft events" do
      expect(subject).not_to permit(regular_user, draft_event)
    end

    it "allows admin to see any event" do
      expect(subject).to permit(admin, draft_event)
      expect(subject).to permit(admin, published_event)
    end

    it "allows the organizer to see their own draft event" do
      expect(subject).to permit(other_organizer, draft_event)
    end

    it "denies an organizer from seeing another organizer's draft" do
      expect(subject).not_to permit(organizer, draft_event)
    end
  end

  permissions :create? do
    it "denies guests" do
      expect(subject).not_to permit(guest, Event.new)
    end

    it "denies regular users" do
      expect(subject).not_to permit(regular_user, Event.new)
    end

    it "allows organizers" do
      expect(subject).to permit(organizer, Event.new)
    end

    it "allows admin" do
      expect(subject).to permit(admin, Event.new)
    end
  end

  permissions :update? do
    it "allows admin" do
      expect(subject).to permit(admin, published_event)
    end

    it "allows the event organizer" do
      expect(subject).to permit(organizer, published_event)
    end

    it "denies another organizer" do
      expect(subject).not_to permit(other_organizer, published_event)
    end

    it "denies regular users" do
      expect(subject).not_to permit(regular_user, published_event)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, published_event)
    end
  end

  permissions :destroy? do
    it "allows admin" do
      expect(subject).to permit(admin, published_event)
    end

    it "allows the event organizer" do
      expect(subject).to permit(organizer, published_event)
    end

    it "denies another organizer" do
      expect(subject).not_to permit(other_organizer, published_event)
    end

    it "denies regular users" do
      expect(subject).not_to permit(regular_user, published_event)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, published_event)
    end
  end

  describe "scope" do
    it "shows only published events to guests" do
      expect(policy_scope(guest, Event)).to contain_exactly(published_event)
    end

    it "shows only published events to regular users" do
      expect(policy_scope(regular_user, Event)).to contain_exactly(published_event)
    end

    it "shows all events to admin" do
      expect(policy_scope(admin, Event)).to contain_exactly(published_event, draft_event)
    end

    it "shows own drafts + all published to organizer" do
      scope = policy_scope(organizer, Event)
      expect(scope).to include(published_event)
      expect(scope).not_to include(draft_event) # draft_event belongs to other_organizer
    end

    it "shows own drafts to the draft's organizer" do
      scope = policy_scope(other_organizer, Event)
      expect(scope).to include(draft_event)
      expect(scope).to include(published_event)
    end
  end

  private

  def policy_scope(user, scope)
    EventPolicy::Scope.new(user, scope).resolve
  end
end
