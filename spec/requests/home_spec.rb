require 'rails_helper'

RSpec.describe "Home and Search Integration", type: :request do
  let!(:category1) { Category.create!(name: "Tecnología", slug: "tecnologia", active: true) }
  let!(:category2) { Category.create!(name: "Música", slug: "musica", active: true) }
  
  let!(:organizer) { 
    User.create!(
      name: "Organizador Test", 
      email: "organizer@test.com", 
      password: "password123",
      active: true
    ).tap { |u| u.roles << Role.find_or_create_by!(name: 'organizer') }
  }

  let!(:published_event1) {
    Event.new(
      name: "Conferencia de React 2026",
      description: "Aprende React de la mano de expertos del desarrollo web.",
      city: "Lima",
      address: "Av. Larco 123",
      start_date: 2.days.from_now,
      end_date: 3.days.from_now,
      currency: "PEN",
      category: category1,
      organizer: organizer,
      status: :published
    ).tap do |event|
      # Usar mock de imagen para saltar validacion
      event.event_images.build(display_order: 0, image: "https://example.com/react.jpg")
      event.save!
    end
  }

  let!(:published_event2) {
    Event.new(
      name: "Festival de Rock Independiente",
      description: "El concierto del año con las mejores bandas de rock indie.",
      city: "Cusco",
      address: "Plaza de Armas S/N",
      start_date: 5.days.from_now,
      end_date: 5.days.from_now + 4.hours,
      currency: "PEN",
      category: category2,
      organizer: organizer,
      status: :published
    ).tap do |event|
      event.event_images.build(display_order: 0, image: "https://example.com/rock.jpg")
      event.save!
    end
  }

  let!(:draft_event) {
    Event.new(
      name: "Taller Borrador de Node.js",
      description: "Aprende Node.js desde cero para desarrollo backend.",
      city: "Arequipa",
      address: "Calle Mercaderes 456",
      start_date: 10.days.from_now,
      end_date: 11.days.from_now,
      currency: "PEN",
      category: category1,
      organizer: organizer,
      status: :draft
    ).tap do |event|
      event.event_images.build(display_order: 0, image: "https://example.com/node.jpg")
      event.save!
    end
  }

  describe "GET /" do
    it "renders the landing page successfully and loads categories and cities" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Descubre eventos")
      expect(response.body).to include("Tecnología")
      expect(response.body).to include("Música")
      
      # Debe incluir Lima y Cusco en el datalist (ciudades de eventos publicados)
      expect(response.body).to include("Lima")
      expect(response.body).to include("Cusco")
      
      # NO debe incluir Arequipa (ciudad de evento borrador)
      expect(response.body).not_to include("Arequipa")
    end

    it "contains the search form pointing to events index" do
      get root_path
      expect(response.body).to include('action="/events"')
      expect(response.body).to include('name="query"')
      expect(response.body).to include('name="category_id"')
      expect(response.body).to include('name="city"')
    end
  end

  describe "Searching from the Hero" do
    it "filters events by text query" do
      get events_path, params: { query: "React" }
      expect(response.body).to include("Conferencia de React 2026")
      expect(response.body).not_to include("Festival de Rock Independiente")
    end

    it "filters events by category" do
      get events_path, params: { category_id: category2.id }
      expect(response.body).to include("Festival de Rock Independiente")
      expect(response.body).not_to include("Conferencia de React 2026")
    end

    it "filters events by city" do
      get events_path, params: { city: "Lima" }
      expect(response.body).to include("Conferencia de React 2026")
      expect(response.body).not_to include("Festival de Rock Independiente")
    end

    it "filters events by multiple parameters combined" do
      get events_path, params: { query: "Rock", city: "Cusco", category_id: category2.id }
      expect(response.body).to include("Festival de Rock Independiente")
      expect(response.body).not_to include("Conferencia de React 2026")
    end
  end
end
