class EventsController < ApplicationController
  before_action :authenticate_user!, only: [:favorite]

  def index
    authorize Event
    sync_selected_city

    base_scope = policy_scope(Event).includes(:category, :organizer, :event_images, :ticket_types)
    @events = Events::SearchQuery.call(base_scope, search_params)
                                 .page(params[:page])
                                 .per(9)

    if @events.empty?
      @suggested_query = find_suggested_query(params[:query]) if params[:query].present?

      # Contextual fallbacks
      city_filter = params[:city].presence || cookies[:selected_city].presence
      category_filter = params[:category_id].presence

      fallback_scope = policy_scope(Event).published.includes(:category, :organizer, :event_images, :ticket_types)

      @fallback_events = []
      if city_filter.present? && city_filter != "all"
        city_events = fallback_scope.by_city(city_filter)
        if category_filter.present?
          scoped = city_events.by_category(category_filter)
          @fallback_events = scoped.any? ? scoped : city_events
        else
          @fallback_events = city_events
        end
      end

      if @fallback_events.blank? && category_filter.present?
        @fallback_events = fallback_scope.by_category(category_filter)
      end

      if @fallback_events.blank?
        @fallback_events = fallback_scope
      end

      @fallback_events = @fallback_events.order(average_rating: :desc, start_date: :asc).limit(3)
    end
  end

  def show
    @event = Event.includes(:ticket_types).find(params[:id])
    authorize @event
    @comments = @event.comments.includes(:user).order(created_at: :desc)
    @comment = Comment.new
  end

  def favorite
    @event = Event.find(params[:id])
    authorize @event

    favorite = current_user.favorites.find_by(event: @event)
    if favorite
      favorite.destroy
      @is_favorited = false
      flash.now[:notice] = "Evento removido de tus favoritos."
    else
      current_user.favorites.create!(event: @event)
      @is_favorited = true
      flash.now[:success] = "¡Evento agregado a tus favoritos!"
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: event_path(@event) }
    end
  end

  def create_alert
    authorize Event
    query = params[:query]
    email = params[:email].presence || current_user&.email

    if email.blank?
      flash[:alert] = "Por favor ingresa un correo electrónico válido."
    elsif query.blank?
      flash[:alert] = "El término de búsqueda no puede estar vacío."
    else
      session[:alerts] ||= []
      session[:alerts] << { query: query, email: email, created_at: Time.current }
      flash[:success] = "¡Alerta creada! Te notificaremos a #{email} cuando haya eventos para '#{query}'."
    end

    redirect_back fallback_location: events_path
  end

  private

  def search_params
    params.permit(:city, :category_id, :query, :start_date, :end_date, :price_min, :price_max)
  end

  def sync_selected_city
    if params[:city].present?
      if params[:city] == "all"
        cookies[:selected_city] = "all"
        params[:city] = nil
      else
        cookies[:selected_city] = sanitize_city(params[:city])
      end
    elsif cookies[:selected_city].present? && cookies[:selected_city] != "all"
      params[:city] = cookies[:selected_city]
    end
  end

  def sanitize_city(city)
    city.to_s.strip.truncate(100)
  end

  def find_suggested_query(query)
    return nil if query.blank?
    query_clean = query.to_s.downcase.strip

    # Candidates list
    candidates = []
    candidates += Category.active.pluck(:name)
    candidates += Event.published.distinct.pluck(:city)
    candidates += Event.published.pluck(:name).flat_map { |n| n.split(/\s+/) }
                       .map { |w| w.gsub(/[^a-zA-ZáéíóúüñÁÉÍÓÚÜÑ]/, '') }
                       .select { |w| w.length > 3 }

    candidates = candidates.compact.uniq.map(&:downcase)

    best_candidate = nil
    min_distance = 999

    candidates.each do |candidate|
      next if candidate == query_clean
      if candidate.include?(query_clean) || query_clean.include?(candidate)
        distance = (candidate.length - query_clean.length).abs
      else
        distance = levenshtein_distance(query_clean, candidate)
      end

      if distance < min_distance
        min_distance = distance
        best_candidate = candidate
      end
    end

    if best_candidate && min_distance <= 3 && min_distance <= (query_clean.length / 2.0).ceil
      original_match = (Category.active.pluck(:name) + Event.published.distinct.pluck(:city) + Event.published.pluck(:name).flat_map { |n| n.split(/\s+/) }).uniq.find { |c| c.downcase == best_candidate }
      original_match || best_candidate
    else
      nil
    end
  end

  def levenshtein_distance(s, t)
    m = s.length
    n = t.length
    return m if n == 0
    return n if m == 0
    d = Array.new(m+1) { Array.new(n+1) }
    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }
    (1..n).each do |j|
      (1..m).each do |i|
        cost = s[i-1] == t[j-1] ? 0 : 1
        d[i][j] = [
          d[i-1][j] + 1,      # deletion
          d[i][j-1] + 1,      # insertion
          d[i-1][j-1] + cost  # substitution
        ].min
      end
    end
    d[m][n]
  end
end
