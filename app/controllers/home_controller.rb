class HomeController < ApplicationController
  def index
    @upcoming_events = Event.upcoming.limit(6)
    @categories = Category.active
  end
end
