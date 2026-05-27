require 'rails_helper'

RSpec.describe "Organizer::Events", type: :request do
  let!(:organizer_role) { Role.find_or_create_by!(name: 'organizer') }
  let!(:user) { User.create!(name: 'Organizador Test', email: 'test@eventos.com', password: 'password123', password_confirmation: 'password123', selected_role: 'organizer') }
  let!(:category) { Category.create!(name: 'Tecnología', slug: 'tecnologia', description: 'Tecnología y eventos') }
  
  # Creamos un evento válido listo para ser publicado
  let!(:draft_event) do
    e = Event.new(
      name: "Evento Borrador",
      description: "Descripción de más de 20 caracteres para pasar la validación de publicación",
      city: "Lima",
      address: "Miraflores",
      start_date: 1.day.from_now,
      end_date: 2.days.from_now,
      price: 0,
      category: category,
      organizer: user,
      status: :draft
    )
    e.event_images.build(image: "https://picsum.photos/200", display_order: 0)
    e.save!
    e
  end

  # Creamos un evento ya publicado
  let!(:published_event) do
    e = Event.new(
      name: "Evento Publicado",
      description: "Descripción de más de 20 caracteres para pasar la validación de publicación",
      city: "Lima",
      address: "Miraflores",
      start_date: 1.day.from_now,
      end_date: 2.days.from_now,
      price: 0,
      category: category,
      organizer: user,
      status: :published
    )
    e.event_images.build(image: "https://picsum.photos/200", display_order: 0)
    e.save!
    e
  end

  before do
    sign_in user
  end

  describe "PATCH /organizer/events/:id" do
    context "when submitting parameters without the event scope" do
      it "returns a 400 Bad Request status and does not modify the event" do
        patch organizer_event_path(draft_event), params: { status: "published" }
        expect(response.status).to eq(400)
        expect(draft_event.reload.status).to eq("draft")
      end
    end

    context "when publishing a draft event with correct event scope" do
      it "successfully transitions the event to published and redirects" do
        patch organizer_event_path(draft_event), params: { event: { status: "published" } }
        expect(response).to redirect_to(organizer_events_path)
        expect(draft_event.reload.status).to eq("published")
      end
    end

    context "when canceling a published event with correct event scope" do
      it "successfully transitions the event to canceled and redirects" do
        patch organizer_event_path(published_event), params: { event: { status: "canceled" } }
        # Note: Organizer::EventsController#update redirects to request.referrer or organizer_events_path
        expect(response).to redirect_to(organizer_events_path)
        expect(published_event.reload.status).to eq("canceled")
      end
    end
  end
end
