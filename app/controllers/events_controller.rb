class EventsController < ApplicationController
  def index
    # Sincronizar parámetro de ciudad con la cookie global
    if params[:city].present?
      if params[:city] == "all"
        cookies[:selected_city] = "all"
        params[:city] = nil
      else
        cookies[:selected_city] = params[:city]
      end
    elsif cookies[:selected_city].present? && cookies[:selected_city] != "all"
      params[:city] = cookies[:selected_city]
    end

    base_scope = policy_scope(Event)
    @events = Events::SearchQuery.call(base_scope, search_params)
                                 .page(params[:page])
                                 .per(9)
    @categories = Category.active
  end

  def show
    @event = Event.find(params[:id])
    authorize @event
    @comments = @event.comments.includes(:user).order(created_at: :desc)
    @comment = Comment.new
  end

  private

  def search_params
    params.permit(:city, :category_id, :query, :start_date, :end_date, :price_min, :price_max)
  end
end
