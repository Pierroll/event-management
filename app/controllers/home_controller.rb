class HomeController < ApplicationController
  def index
    if user_signed_in?
      if current_user.admin?
        redirect_to admin_dashboard_path and return
      elsif current_user.organizer?
        redirect_to organizer_events_path and return
      end
    end

    @upcoming_events = Event.upcoming.limit(6)
    @categories = Category.active
    @cities = Event.published_only.distinct.pluck(:city).compact_blank.sort
  end
end
