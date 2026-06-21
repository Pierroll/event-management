class HomeController < ApplicationController
  def index
    if user_signed_in?
      if current_user.admin?
        redirect_to admin_dashboard_path and return
      elsif current_user.organizer?
        redirect_to organizer_events_path and return
      end
    end

    @upcoming_events = Event.upcoming.includes(:ticket_types).limit(6)
    @cities = Event.published.distinct.pluck(:city).compact_blank.sort

    # Cargar eventos destacados con imágenes para el Hero
    # Eager loading de event_images para evitar queries N+1
    hero_candidates = Event.upcoming
                           .joins(:event_images)
                           .includes(:event_images)
                           .distinct
                           .limit(10)
                           .to_a
    @hero_events = hero_candidates.shuffle(random: Random.new(Time.current.hour)).first(5)
  end
end
