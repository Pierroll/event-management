module ApplicationHelper
  def navbar_categories
    Category.active.order(:name)
  end

  def navbar_cities
    Event.published.distinct.pluck(:city).compact_blank.sort
  end

  # Genera un badge visual para el estado de un evento.
  # Acepta `classes:` para agregar/adicionar clases CSS extras al span.
  # El badge se renderiza siempre; el caller decide si mostrarlo condicionalmente.
  def selected_city_label(fallback: "Ubicación")
    city = cookies[:selected_city]
    return fallback if city.blank? || city == "all"
    city
  end

  def event_status_badge(event, classes: "")
    colors = case event.status
             when "published" then "bg-green-100 text-green-800"
             when "draft"     then "bg-yellow-100 text-yellow-800"
             when "canceled"  then "bg-red-100 text-red-800"
             when "finished"  then "bg-gray-100 text-gray-800"
             end

    tag.span event.status.humanize,
             class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{colors} #{classes}"
  end
end
