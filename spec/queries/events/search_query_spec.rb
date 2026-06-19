require 'rails_helper'

RSpec.describe Events::SearchQuery, type: :query do
  let(:category) { Category.create!(name: "Test", slug: "test-sq") }
  let(:organizer) do
    User.create!(name: "Org", email: "org.sq@test.com", password: "password123").tap do |u|
      u.roles << Role.find_or_create_by!(name: "organizer")
    end
  end

  # Helper to create an event with ticket_types
  def event_with_tickets(name:, ticket_prices:)
    event = Event.new(
      name: name,
      description: "Description for #{name} with enough chars.",
      city: "Lima",
      address: "Av. Test",
      start_date: 1.day.from_now,
      end_date: 1.day.from_now + 2.hours,
      currency: "PEN",
      category: category,
      organizer: organizer,
      status: :published
    )
    event.event_images.build(display_order: 0, image: "https://example.com/img.jpg")

    ticket_prices.each_with_index do |price, idx|
      event.ticket_types.build(
        name: "Ticket #{idx}",
        price: price,
        quantity_total: 100
      )
    end

    event.save!
    event
  end

  let!(:cheap_event)  { event_with_tickets(name: "Barato",  ticket_prices: [10, 20]) }
  let!(:mid_event)    { event_with_tickets(name: "Medio",   ticket_prices: [50, 80]) }
  let!(:expensive_ev) { event_with_tickets(name: "Caro",    ticket_prices: [150, 200]) }
  let!(:wide_event)   { event_with_tickets(name: "Variado", ticket_prices: [10, 100, 500]) }
  let!(:free_event)   { event_with_tickets(name: "Gratis",  ticket_prices: [0]) }

  describe ".call" do
    it "returns all events when no price params" do
      results = Events::SearchQuery.call(Event.all, {})
      expect(results).to include(cheap_event, mid_event, expensive_ev, wide_event, free_event)
    end

    describe "filtering by price_min" do
      it "returns events with at least one ticket_type >= price_min" do
        results = Events::SearchQuery.call(Event.all, { price_min: 50 })
        expect(results).to include(mid_event, expensive_ev, wide_event)
        expect(results).not_to include(cheap_event, free_event)
      end

      it "works with zero as min" do
        results = Events::SearchQuery.call(Event.all, { price_min: 0 })
        expect(results).to include(cheap_event, mid_event, expensive_ev, wide_event, free_event)
      end

      it "returns empty when no event has tickets above threshold" do
        results = Events::SearchQuery.call(Event.all, { price_min: 9999 })
        expect(results).to be_empty
      end
    end

    describe "filtering by price_max" do
      it "returns events with at least one ticket_type <= price_max" do
        results = Events::SearchQuery.call(Event.all, { price_max: 50 })
        expect(results).to include(cheap_event, mid_event, wide_event, free_event)
        expect(results).not_to include(expensive_ev)
      end

      it "returns only free events when max is 0" do
        results = Events::SearchQuery.call(Event.all, { price_max: 0 })
        expect(results).to include(free_event)
        expect(results).not_to include(cheap_event, mid_event, expensive_ev, wide_event)
      end
    end

    describe "filtering by both price_min and price_max" do
      it "returns events with ticket_types in the range" do
        results = Events::SearchQuery.call(Event.all, { price_min: 30, price_max: 100 })
        expect(results).to include(mid_event, wide_event)  # wide_event has S/100
        expect(results).not_to include(cheap_event, expensive_ev, free_event)
      end

      it "returns events spanning the range boundary" do
        # wide_event has prices [10, 100, 500] — S/10 ticket is in range
        results = Events::SearchQuery.call(Event.all, { price_min: 5, price_max: 60 })
        expect(results).to include(cheap_event, mid_event, wide_event)
        expect(results).not_to include(expensive_ev, free_event)
      end

      it "returns empty when range excludes everything" do
        results = Events::SearchQuery.call(Event.all, { price_min: 600, price_max: 700 })
        expect(results).to be_empty
      end
    end

    describe "events with multiple ticket_types" do
      it "matches if ANY ticket_type is in range, even if others aren't" do
        # wide_event has S/10, S/100, S/500 — S/500 is way above
        results = Events::SearchQuery.call(Event.all, { price_min: 400, price_max: 600 })
        expect(results).to include(wide_event)
        expect(results).not_to include(cheap_event, mid_event, expensive_ev, free_event)
      end

      it "excludes event when NO ticket_type is in range" do
        results = Events::SearchQuery.call(Event.all, { price_min: 30, price_max: 40 })
        expect(results).to be_empty
      end
    end

    describe "events without ticket_types" do
      let!(:no_tickets) do
        event = Event.new(
          name: "Sin Tickets",
          description: "An event with no ticket types at all.",
          city: "Lima",
          address: "Av. Test",
          start_date: 1.day.from_now,
          end_date: 1.day.from_now + 2.hours,
          currency: "PEN",
          category: category,
          organizer: organizer,
          status: :published
        )
        event.event_images.build(display_order: 0, image: "https://example.com/no-tickets.jpg")
        event.save!
        event
      end

      it "never matches any price filter" do
        results = Events::SearchQuery.call(Event.all, { price_min: 0 })
        expect(results).not_to include(no_tickets)
      end

      it "does not cause SQL errors" do
        expect {
          Events::SearchQuery.call(Event.all, { price_min: 10, price_max: 100 })
        }.not_to raise_error
      end
    end
  end
end
