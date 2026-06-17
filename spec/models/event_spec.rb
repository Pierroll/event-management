require 'rails_helper'

RSpec.describe Event, type: :model do
  let(:category) { Category.create!(name: "Test", slug: "test-ev") }
  let(:organizer) do
    User.create!(name: "Org", email: "org@ev.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end

  describe "validations" do
    it "is valid with basic draft attributes" do
      event = Event.new(
        name: "Mi Evento",
        category: category,
        organizer: organizer,
        status: :draft
      )
      event.event_images.build(display_order: 0, image: "https://example.com/img.jpg")
      expect(event).to be_valid
    end

    it "requires a name" do
      event = Event.new(name: nil, organizer: organizer)
      expect(event).not_to be_valid
      expect(event.errors[:name]).to include("no puede estar en blanco")
    end

    it "requires at least one image" do
      event = Event.new(name: "No Image", organizer: organizer, category: category)
      expect(event).not_to be_valid
      expect(event.errors[:base]).to include("Debes subir al menos una imagen para registrar el evento")
    end

    it "allows image via primary_image_param (virtual attr)" do
      event = Event.new(name: "Virtual Image", organizer: organizer, category: category)
      event.primary_image_param = "https://example.com/virtual.jpg"
      expect(event).to be_valid
    end

    describe "published validations" do
      it "requires description (min 20 chars) when publishing" do
        event = Event.new(
          name: "Test",
          description: "Corto",
          city: "Lima",
          address: "Av. Test",
          start_date: 1.day.from_now,
          end_date: 1.day.from_now + 2.hours,
          price: 10,
          category: category,
          organizer: organizer,
          status: :published
        )
        event.event_images.build(display_order: 0, image: "https://example.com/img.jpg")
        expect(event).not_to be_valid
        expect(event.errors[:description]).to include("es demasiado corto (20 caracteres mínimo)")
      end

      it "requires city when publishing" do
        event = Event.new(
          name: "Test",
          description: "A valid description for test purposes.",
          city: nil,
          address: "Av. Test",
          start_date: 1.day.from_now,
          category: category,
          organizer: organizer,
          status: :published
        )
        event.event_images.build(display_order: 0, image: "https://example.com/img.jpg")
        expect(event).not_to be_valid
        expect(event.errors[:city]).to include("no puede estar en blanco")
      end

      it "is valid with all required fields when publishing" do
        event = Event.new(
          name: "Evento Completo",
          description: "Una descripción larga y completa para validar la publicación.",
          city: "Lima",
          address: "Av. Arequipa 1234",
          start_date: 1.day.from_now,
          end_date: 1.day.from_now + 3.hours,
          price: 50,
          currency: "PEN",
          category: category,
          organizer: organizer,
          status: :published
        )
        event.event_images.build(display_order: 0, image: "https://example.com/img.jpg")
        expect(event).to be_valid
      end
    end

    describe "price" do
      it "defaults to 0" do
        event = Event.new(organizer: organizer)
        expect(event.price).to eq(0)
      end

      it "must be greater than or equal to 0" do
        event = Event.new(name: "Test", price: -1, organizer: organizer)
        expect(event).not_to be_valid
        expect(event.errors[:price]).to include("debe ser mayor que o igual a 0")
      end
    end

    describe "average_rating" do
      it "defaults to 0" do
        event = Event.new(organizer: organizer)
        expect(event.average_rating).to eq(0)
      end

      it "must be between 0 and 5" do
        event = Event.new(name: "Test", average_rating: 6, organizer: organizer)
        expect(event).not_to be_valid
        expect(event.errors[:average_rating]).to include("debe ser menor que o igual a 5")
      end
    end

    describe "end_date_after_start_date" do
      it "is valid when end_date is after start_date" do
      event = Event.new(
        name: "Test",
        start_date: Time.current,
        end_date: 2.hours.from_now,
        category: category,
        organizer: organizer
      )
        event.event_images.build(display_order: 0, image: "https://example.com/img.jpg")
        expect(event).to be_valid
      end

      it "is invalid when end_date equals start_date" do
        now = Time.current
        event = Event.new(
          name: "Test",
          start_date: now,
          end_date: now,
          organizer: organizer
        )
        event.event_images.build(display_order: 0, image: "https://example.com/img.jpg")
        expect(event).not_to be_valid
        expect(event.errors[:end_date]).to include("debe ser posterior a la fecha de inicio")
      end

      it "is invalid when end_date is before start_date" do
        event = Event.new(
          name: "Test",
          start_date: Time.current,
          end_date: 1.hour.ago,
          organizer: organizer
        )
        event.event_images.build(display_order: 0, image: "https://example.com/img.jpg")
        expect(event).not_to be_valid
        expect(event.errors[:end_date]).to include("debe ser posterior a la fecha de inicio")
      end
    end
  end

  describe "scopes" do
    let!(:past_event) do
      Event.new(
        name: "Pasado",
        description: "An event that already happened.",
        city: "Lima",
        address: "Av. Test 1",
        start_date: 2.days.ago,
        end_date: 2.days.ago + 2.hours,
        price: 0,
        category: category,
        organizer: organizer,
        status: :published
      ).tap { |e| e.event_images.build(display_order: 0, image: "https://example.com/p.jpg"); e.save! }
    end

    let!(:future_event) do
      Event.new(
        name: "Futuro",
        description: "An upcoming event for testing.",
        city: "Lima",
        address: "Av. Test 2",
        start_date: 2.days.from_now,
        end_date: 2.days.from_now + 2.hours,
        price: 0,
        category: category,
        organizer: organizer,
        status: :published
      ).tap { |e| e.event_images.build(display_order: 0, image: "https://example.com/f.jpg"); e.save! }
    end

    let!(:draft_event) do
      Event.new(
        name: "Borrador",
        description: "A draft event not yet visible.",
        city: "Lima",
        address: "Av. Test 3",
        start_date: 3.days.from_now,
        end_date: 3.days.from_now + 2.hours,
        price: 0,
        category: category,
        organizer: organizer,
        status: :draft
      ).tap { |e| e.event_images.build(display_order: 0, image: "https://example.com/d.jpg"); e.save! }
    end

    it ".published_only returns only published events" do
      expect(Event.published_only).to include(past_event, future_event)
      expect(Event.published_only).not_to include(draft_event)
    end

    it ".upcoming returns future published events" do
      expect(Event.upcoming).to include(future_event)
      expect(Event.upcoming).not_to include(past_event, draft_event)
    end

    it ".by_city filters by city" do
      cusco_event = Event.new(
        name: "Cusco",
        description: "A tech event in Cusco city.",
        city: "Cusco",
        address: "Av. Cusco",
        start_date: 1.day.from_now,
        end_date: 1.day.from_now + 2.hours,
        price: 0,
        category: category,
        organizer: organizer,
        status: :published
      ).tap { |e| e.event_images.build(display_order: 0, image: "https://example.com/c.jpg"); e.save! }

      expect(Event.by_city("Cusco")).to include(cusco_event)
      expect(Event.by_city("Cusco")).not_to include(future_event)
    end

    it ".by_category filters by category" do
      other_cat = Category.create!(name: "Other", slug: "other-cat")
      other_event = Event.new(
        name: "Other Cat",
        description: "An event in another category.",
        city: "Lima",
        address: "Av. Other",
        start_date: 1.day.from_now,
        end_date: 1.day.from_now + 2.hours,
        price: 0,
        category: other_cat,
        organizer: organizer,
        status: :published
      ).tap { |e| e.event_images.build(display_order: 0, image: "https://example.com/o.jpg"); e.save! }

      expect(Event.by_category(other_cat.id)).to include(other_event)
      expect(Event.by_category(other_cat.id)).not_to include(future_event)
    end
  end

  describe "methods" do
    it "#primary_image returns the first event image" do
      event = Event.new(name: "Test", organizer: organizer)
      img = event.event_images.build(display_order: 0, image: "https://example.com/p.jpg")
      expect(event.primary_image).to eq(img)
    end

    it "#secondary_images returns images after the first one" do
      event = Event.new(name: "Test", organizer: organizer)
      img1 = event.event_images.build(display_order: 0, image: "https://example.com/1.jpg")
      img2 = event.event_images.build(display_order: 1, image: "https://example.com/2.jpg")
      img3 = event.event_images.build(display_order: 2, image: "https://example.com/3.jpg")
      expect(event.secondary_images).to contain_exactly(img2, img3)
    end

    it "#secondary_images returns empty when only one image" do
      event = Event.new(name: "Test", organizer: organizer)
      event.event_images.build(display_order: 0, image: "https://example.com/1.jpg")
      expect(event.secondary_images).to be_empty
    end
  end
end
