# frozen_string_literal: true

class CreateTicketTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_types do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.integer :quantity_total, null: false
      t.integer :max_per_order, default: 10
      t.datetime :sales_start_at
      t.datetime :sales_end_at
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
