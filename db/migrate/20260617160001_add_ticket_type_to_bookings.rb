# frozen_string_literal: true

class AddTicketTypeToBookings < ActiveRecord::Migration[8.1]
  def change
    add_reference :bookings, :ticket_type, foreign_key: true
    add_column :bookings, :expires_at, :datetime
    add_column :bookings, :unit_price, :decimal, precision: 10, scale: 2
  end
end
