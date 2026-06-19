# frozen_string_literal: true

class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.references :booking, null: false, foreign_key: true
      t.string :qr_code, null: false
      t.string :attendee_name
      t.string :attendee_email
      t.integer :status, null: false, default: 0
      t.datetime :checked_in_at

      t.timestamps
    end

    add_index :tickets, :qr_code, unique: true
  end
end
