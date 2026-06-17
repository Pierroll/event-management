# frozen_string_literal: true

class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.datetime :booked_at, null: false

      # Future payment columns (not used yet — demo mode)
      # t.string :payment_method
      # t.datetime :paid_at
      # t.string :stripe_payment_intent_id

      t.timestamps
    end

    add_index :bookings, [:event_id, :status], name: "index_bookings_on_event_and_status"
    add_index :bookings, [:user_id, :event_id], name: "index_bookings_on_user_and_event"
  end
end
