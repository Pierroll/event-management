require 'rails_helper'

RSpec.describe Favorite, type: :model do
  describe 'associations' do
    it "belongs to user and event" do
      user = User.create!(name: "Test User", email: "user@test.com", password: "password123")
      category = Category.create!(name: "Test Cat", slug: "test-cat")
      event = Event.new(name: "Test Event", description: "Hello world", address: "123 Main St", city: "Lima", start_date: Time.current + 1.day, organizer: user, category: category)
      event.event_images.build(display_order: 0, image: "https://example.com/image.jpg")
      event.save!
      favorite = Favorite.new(user: user, event: event)
      expect(favorite.user).to eq(user)
      expect(favorite.event).to eq(event)
    end
  end

  describe 'validations' do
    it 'validates uniqueness of event_id scoped to user_id' do
      user = User.create!(name: "Test User", email: "user@test.com", password: "password123")
      category = Category.create!(name: "Test Cat", slug: "test-cat")
      event = Event.new(name: "Test Event", description: "Hello world", address: "123 Main St", city: "Lima", start_date: Time.current + 1.day, organizer: user, category: category)
      event.event_images.build(display_order: 0, image: "https://example.com/image.jpg")
      event.save!
      
      Favorite.create!(user: user, event: event)
      duplicate = Favorite.new(user: user, event: event)
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:event_id]).to include('ya está en tus favoritos')
    end
  end
end
