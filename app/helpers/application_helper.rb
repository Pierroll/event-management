module ApplicationHelper
  def navbar_categories
    Category.active.order(:name)
  end
end
