module ApplicationHelper
  def navbar_categories
    Category.active.order(:name)
  end

  def navbar_cities
    Event.published_only.distinct.pluck(:city).compact_blank.sort
  end
end
