class AddCheckInEnabledToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :check_in_enabled, :boolean, default: false, null: false
  end
end
