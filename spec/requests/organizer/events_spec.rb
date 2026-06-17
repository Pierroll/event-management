require 'rails_helper'

RSpec.describe "Organizer::Events", type: :request do
  let!(:organizer_role) { Role.find_or_create_by!(name: 'organizer') }
  let!(:user) { User.create!(name: 'Organizador Test', email: 'test@eventos.com', password: 'password123', password_confirmation: 'password123', selected_role: 'organizer', confirmed_at: Time.current) }
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
        expect(response).to redirect_to(organizer_events_path)
        expect(published_event.reload.status).to eq("canceled")
      end
    end
  end

  describe "POST /organizer/events" do
    let(:primary_file) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: Tempfile.new(['primary', '.jpg']),
        filename: 'primary.jpg',
        content_type: 'image/jpeg'
      )
    end
    let(:secondary1) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: Tempfile.new(['sec1', '.jpg']),
        filename: 'sec1.jpg',
        content_type: 'image/jpeg'
      )
    end
    let(:secondary2) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: Tempfile.new(['sec2', '.jpg']),
        filename: 'sec2.jpg',
        content_type: 'image/jpeg'
      )
    end

    it "creates an event with primary and multiple secondary images" do
      event_params = {
        name: "Nuevo Evento Con Imagenes",
        description: "Esta es una descripcion con mas de veinte caracteres.",
        city: "Lima",
        address: "Av. Larco 123",
        start_date: 2.days.from_now,
        price: 0,
        category_id: category.id,
        status: "published",
        primary_image: primary_file,
        images: [secondary1, secondary2]
      }

      expect {
        post organizer_events_path, params: { event: event_params }
      }.to change(Event, :count).by(1)

      new_event = Event.last
      expect(response).to redirect_to(organizer_event_path(new_event))
      expect(new_event.event_images.count).to eq(3)

      # La principal tiene display_order = 0
      expect(new_event.event_images.find_by(display_order: 0)).to be_present
      # Las secundarias tienen display_order > 0
      expect(new_event.event_images.where("display_order > 0").count).to eq(2)
    end
  end

  describe "PATCH /organizer/events/:id" do
    let(:new_secondary) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: Tempfile.new(['sec_new', '.jpg']),
        filename: 'sec_new.jpg',
        content_type: 'image/jpeg'
      )
    end

    it "allows adding new secondary images in edit mode" do
      expect {
        patch organizer_event_path(draft_event), params: {
          event: {
            images: [new_secondary]
          }
        }
      }.to change(draft_event.event_images, :count).by(1)

      expect(draft_event.reload.event_images.count).to eq(2)
      expect(draft_event.event_images.pluck(:display_order)).to match_array([0, 1])
    end
  end
end
