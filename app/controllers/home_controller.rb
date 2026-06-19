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
  end
end
