require 'rails_helper'

RSpec.describe Event, type: :model do
  let!(:category) { Category.create!(name: "Tecnología", slug: "tecnologia", active: true) }
  let!(:organizer) { 
    User.create!(
      name: "Organizador Local", 
      email: "organizer.map@test.com", 
      password: "password123",
      active: true
    ).tap { |u| u.roles << Role.find_or_create_by!(name: 'organizer') }
  }

  before do
    # Configurar el Geocoder en modo test para evitar llamadas de red a Nominatim
    Geocoder.configure(lookup: :test, ip_lookup: :test)
    Geocoder::Lookup::Test.add_stub(
      "Av. Arequipa 4567, Lima", [
        {
          'coordinates'  => [-12.08331, -77.03442],
          'address'      => 'Av. Arequipa 4567, Lima',
          'city'         => 'Lima',
          'state'        => 'Lima',
          'country'      => 'Peru',
          'country_code' => 'pe'
        }
      ]
    )
  end

  describe "Geocoding Callbacks" do
    it "automatically geocodes on save if coordinates are empty and address is present" do
      event = Event.new(
        name: "Ruby Meetup",
        description: "Charla y networking de Ruby de la mano de expertos del desarrollo web.",
        city: "Lima",
        address: "Av. Arequipa 4567, Lima",
        start_date: 3.days.from_now,
        category: category,
        organizer: organizer,
        status: :draft
      )
      
      # Mock de imágenes para saltar validacion
      event.event_images.build(display_order: 0, image: "https://example.com/logo.jpg")
      
      expect(event.latitude).to be_nil
      expect(event.longitude).to be_nil
      
      event.save!
      
      expect(event.latitude).to be_within(0.0001).of(-12.08331)
      expect(event.longitude).to be_within(0.0001).of(-77.03442)
    end

    it "does NOT overwrite existing coordinates if they are already provided" do
      event = Event.new(
        name: "Rails Summit",
        description: "Charla y networking de Ruby de la mano de expertos del desarrollo web.",
        city: "Lima",
        address: "Av. Arequipa 4567, Lima",
        latitude: -12.11111,
        longitude: -77.22222,
        start_date: 3.days.from_now,
        category: category,
        organizer: organizer,
        status: :draft
      )
      
      event.event_images.build(display_order: 0, image: "https://example.com/logo.jpg")
      event.save!
      
      # Deben mantenerse las coordenadas provistas en lugar de las geocodificadas del stub
      expect(event.latitude).to eq(-12.11111)
      expect(event.longitude).to eq(-77.22222)
    end
  end
end
