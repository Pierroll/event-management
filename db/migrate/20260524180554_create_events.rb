class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.text :description, null: false

      t.references :organizer,
                   null: false,
                   foreign_key: { to_table: :users }

      t.references :category,
                   null: false,
                   foreign_key: true

      t.datetime :start_date, null: false
      t.datetime :end_date

      t.string :city, null: false
      t.string :address, null: false

      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8

      t.decimal :price,
                precision: 10,
                scale: 2,
                default: 0,
                null: false

      t.string :currency,
               limit: 3,
               default: "PEN",
               null: false

      t.integer :max_capacity

      # enum Rails
      t.integer :status,
                default: 0,
                null: false

      t.decimal :average_rating,
                precision: 3,
                scale: 2,
                default: 0,
                null: false

      t.timestamps
    end

    add_index :events, :status
    add_index :events, :city
    add_index :events, :start_date
  end
end