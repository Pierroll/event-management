require 'rails_helper'

RSpec.describe "Location and City Filter Integration", type: :request do
  let!(:category) { Category.create!(name: "Tecnología", slug: "tecnologia", active: true) }
  
  let!(:organizer) { 
    User.create!(
      name: "Organizador Local", 
      email: "organizer.local@test.com", 
      password: "password123",
      active: true
    ).tap { |u| u.roles << Role.find_or_create_by!(name: 'organizer') }
  }

  let!(:lima_event) {
    Event.new(
      name: "Encuentro de Ruby en Lima",
      description: "Charla y networking de Ruby y Rails en la capital.",
      city: "Lima",
      address: "Av. Arequipa 4567",
      start_date: 3.days.from_now,
      end_date: 3.days.from_now + 3.hours,
      price: 10.00,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    ).tap do |event|
      event.event_images.build(display_order: 0, image: "https://example.com/ruby_lima.jpg")
      event.save!
    end
  }

  let!(:cusco_event) {
    Event.new(
      name: "Tech Summit Cusco 2026",
      description: "Tecnología en el corazón del imperio de los Incas.",
      city: "Cusco",
      address: "Portal de Harinas 23",
      start_date: 6.days.from_now,
      end_date: 7.days.from_now,
      price: 180.00,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    ).tap do |event|
      event.event_images.build(display_order: 0, image: "https://example.com/tech_cusco.jpg")
      event.save!
    end
  }

  describe "Syncing params[:city] to cookies[:selected_city]" do
    it "sets the cookie when city parameter is present" do
      get events_path, params: { city: "Lima" }
      expect(response).to have_http_status(:ok)
      expect(cookies[:selected_city]).to eq("Lima")
      expect(response.body).to include("Encuentro de Ruby en Lima")
      expect(response.body).not_to include("Tech Summit Cusco 2026")
    end

    it "sets the cookie to 'all' and clears parameter if city parameter is 'all'" do
      get events_path, params: { city: "all" }
      expect(response).to have_http_status(:ok)
      expect(cookies[:selected_city]).to eq("all")
      expect(response.body).to include("Encuentro de Ruby en Lima")
      expect(response.body).to include("Tech Summit Cusco 2026")
    end
  end

  describe "Filtering by cookie value when params[:city] is absent" do
    it "uses the selected_city cookie to filter events" do
      # Simulamos que el usuario tiene la cookie de "Cusco" guardada de visitas previas
      cookies[:selected_city] = "Cusco"
      
      get events_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tech Summit Cusco 2026")
      expect(response.body).not_to include("Encuentro de Ruby en Lima")
    end

    it "does not filter if the selected_city cookie is 'all'" do
      cookies[:selected_city] = "all"
      
      get events_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tech Summit Cusco 2026")
      expect(response.body).to include("Encuentro de Ruby en Lima")
    end
  end
end
