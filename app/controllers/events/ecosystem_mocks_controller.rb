module Events
  class EcosystemMocksController < ApplicationController
    skip_after_action :verify_authorized
    layout false

    def index
      @event = Event.find(params[:event_id])
      
      # Mock Data: Simulando llamadas a APIs de otros equipos
      @hotels = [
        { name: "Grand Hotel #{@event.city || 'Central'}", rating: 4.8, price: 120, distance: "0.5 km", image: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500&q=80" },
        { name: "Boutique Stay", rating: 4.5, price: 85, distance: "1.2 km", image: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=500&q=80" }
      ]
      
      @branches = [
        { name: "Hertz Aeropuerto", location: "Aeropuerto Velasco Astete", price_from: 120, fleet_size: 15, image: "https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=500&q=80" },
        { name: "Avis Centro Histórico", location: "Plaza de Armas", price_from: 95, fleet_size: 8, image: "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=500&q=80" }
      ]

      @restaurants = [
        { name: "La Trattoria del Centro", cuisine: "Italiana", rating: 4.9, distance: "0.3 km", image: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500&q=80" },
        { name: "Sushi Central", cuisine: "Japonesa", rating: 4.7, distance: "0.8 km", image: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=500&q=80" }
      ]
      
    end
  end
end
