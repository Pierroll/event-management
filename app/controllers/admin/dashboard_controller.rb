module Admin
  class DashboardController < BaseController
    def index
      @total_users = User.count
      @total_events = Event.count
      @total_comments = Comment.count
      @published_events = Event.published_only.count
    end
  end
end
