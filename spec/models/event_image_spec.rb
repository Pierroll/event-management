require 'rails_helper'

RSpec.describe EventImage, type: :model do
  let(:category) { Category.create!(name: "Test", slug: "test-ei") }
  let(:organizer) do
    User.create!(name: "Org", email: "org@ei.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end
  let(:event) do
    Event.new(
      name: "Test Event",
      description: "A test for event images.",
      city: "Lima",
      address: "Av. Test 123",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      price: 0,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    ).tap { |e| e.event_images.build(display_order: 0, image: "https://example.com/e.jpg"); e.save! }
  end

  describe "validations" do
    it "is valid with an image URL" do
      image = EventImage.new(event: event, image: "https://example.com/img.jpg", display_order: 1)
      expect(image).to be_valid
    end

    it "requires either image or file" do
      image = EventImage.new(event: event, image: nil, display_order: 1)
      expect(image).not_to be_valid
      expect(image.errors[:base]).to include("Debe proporcionar una URL de imagen o adjuntar un archivo")
    end
  end

  describe "defaults" do
    it "defaults display_order to 0" do
      image = EventImage.new(event: event, image: "https://example.com/img.jpg")
      expect(image.display_order).to eq(0)
    end
  end

  describe "ordering" do
    it "orders by display_order ascending" do
      event.reload.event_images.destroy_all
      img0 = EventImage.create!(event: event, image: "https://example.com/0.jpg", display_order: 0)
      img1 = EventImage.create!(event: event, image: "https://example.com/1.jpg", display_order: 1)
      img2 = EventImage.create!(event: event, image: "https://example.com/2.jpg", display_order: 2)

      expect(EventImage.ordered.to_a).to eq([img0, img1, img2])
    end
  end

  describe "image_url" do
    it "returns the image column when no file is attached" do
      image = EventImage.new(event: event, image: "https://example.com/img.jpg")
      expect(image.image_url).to eq("https://example.com/img.jpg")
    end
  end
end
