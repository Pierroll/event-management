class CreateEventImages < ActiveRecord::Migration[8.1]
  def change
    create_table :event_images do |t|
      t.references :event, null: false, foreign_key: true
      t.string :image, null: false
      t.integer :display_order, default: 0, null: false

      t.timestamps
    end
  end
end
