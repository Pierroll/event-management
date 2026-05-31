require 'rails_helper'

RSpec.describe "Public Events Details", type: :request do
  let!(:category) { Category.create!(name: "Conciertos", slug: "conciertos", active: true) }
  let!(:organizer) {
    User.create!(
      name: "Organizador Principal",
      email: "organizer.main@test.com",
      password: "password123",
      active: true
    ).tap { |u| u.roles << Role.find_or_create_by!(name: 'organizer') }
  }

  let!(:event_with_coordinates) {
    Event.new(
      name: "Concierto de Rock con Mapa",
      description: "Evento espectacular con ubicación en el mapa.",
      city: "Lima",
      address: "Av. Arequipa 1234",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 3.hours,
      price: 45.00,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published,
      latitude: -12.071234,
      longitude: -77.037890
    ).tap do |e|
      e.event_images.build(display_order: 0, image: "https://example.com/image.jpg")
      e.save!
    end
  }

  let!(:event_without_coordinates) {
    Event.new(
      name: "Taller Online sin Mapa",
      description: "Evento sin ubicación física o coordenadas.",
      city: "Lima",
      address: "Dirección Virtual",
      start_date: 2.days.from_now,
      end_date: 2.days.from_now + 2.hours,
      price: 0.00,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    ).tap do |e|
      e.event_images.build(display_order: 0, image: "https://example.com/image2.jpg")
      e.save!
      # Usamos update_columns para saltar el callback de Geocoder que asigna coordenadas por default
      e.update_columns(latitude: nil, longitude: nil)
    end
  }

  describe "GET /events/:id" do
    it "renders the map container with correct lat/lng data attributes when coordinates are present" do
      get event_path(event_with_coordinates)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="event-map"')
      expect(response.body).to include('data-lat="-12.071234"')
      expect(response.body).to include('data-lng="-77.03789"')
      expect(response.body).to include('data-controller="event-detail"')
      expect(response.body).to include('Ubicación en mapa')
    end

    it "does not render the map container when coordinates are not present" do
      get event_path(event_without_coordinates)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('id="event-map"')
      expect(response.body).not_to include('Ubicación en mapa')
    end
  end
end
