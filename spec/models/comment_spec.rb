require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:category) { Category.create!(name: "Test Cat", slug: "test-cat") }
  let(:organizer) do
    User.create!(name: "Org", email: "org@comment.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:user) { User.create!(name: "User", email: "user@comment.com", password: "password123") }
  let(:event) do
    Event.new(
      name: "Test Event",
      description: "A test event for comments.",
      city: "Lima",
      address: "Av. Test 123",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    ).tap { |e| e.event_images.build(display_order: 0, image: "https://example.com/e.jpg"); e.save! }
  end

  describe "validations" do
    it "is valid with content and rating" do
      comment = Comment.new(content: "Excelente evento, me encantó!", rating: 5, user: user, event: event)
      expect(comment).to be_valid
    end

    it "requires content" do
      comment = Comment.new(content: nil, rating: 5, user: user, event: event)
      expect(comment).not_to be_valid
      expect(comment.errors[:content]).to include("no puede estar en blanco")
    end

    it "requires content with at least 10 characters" do
      comment = Comment.new(content: "Corto", rating: 5, user: user, event: event)
      expect(comment).not_to be_valid
      expect(comment.errors[:content]).to include("es demasiado corto (10 caracteres mínimo)")
    end

    it "requires content with at most 1000 characters" do
      comment = Comment.new(content: "a" * 1001, rating: 5, user: user, event: event)
      expect(comment).not_to be_valid
      expect(comment.errors[:content]).to include("es demasiado largo (1000 caracteres máximo)")
    end

    it "requires rating between 1 and 5" do
      comment = Comment.new(content: "Un evento buenísimo!", rating: 6, user: user, event: event)
      expect(comment).not_to be_valid
      expect(comment.errors[:rating]).to include("no está incluido en la lista")
    end

    it "allows rating of 1" do
      comment = Comment.new(content: "No me gustó para nada.", rating: 1, user: user, event: event)
      expect(comment).to be_valid
    end

    it "allows rating of 5" do
      comment = Comment.new(content: "Excelente evento, muy recomendado!", rating: 5, user: user, event: event)
      expect(comment).to be_valid
    end

    it "enforces one comment per user per event" do
      Comment.create!(content: "Primer comentario de prueba.", rating: 4, user: user, event: event)
      duplicate = Comment.new(content: "Segundo comentario de prueba.", rating: 3, user: user, event: event)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("already commented on this event")
    end
  end

  describe "callbacks" do
    # after_save rating update is handled by Comments::CreateService.
    # These tests go through the service to verify the full flow.

    it "updates event average_rating after save via service" do
      expect {
        Comments::CreateService.call(user, event, { content: "Gran evento, muy educativo!", rating: 4 })
      }.to change { event.reload.average_rating }.from(0).to(4.0)
    end

    it "recalculates average_rating after destroy" do
      Comments::CreateService.call(user, event, { content: "Comentario único de calificación.", rating: 3 })
      comment = event.comments.first!
      expect {
        comment.destroy
      }.to change { event.reload.average_rating }.from(3.0).to(0.0)
    end

    it "averages multiple comments correctly" do
      other_user = User.create!(name: "Other", email: "other@comment.com", password: "password123")
      Comments::CreateService.call(user, event, { content: "Buen evento, me gustó.", rating: 5 })
      Comments::CreateService.call(other_user, event, { content: "Estuvo regular nomas.", rating: 3 })

      expect(event.reload.average_rating).to eq(4.0)
    end
  end
end
