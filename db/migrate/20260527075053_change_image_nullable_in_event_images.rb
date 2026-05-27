class ChangeImageNullableInEventImages < ActiveRecord::Migration[8.1]
  def change
    change_column_null :event_images, :image, true
  end
end
