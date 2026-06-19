# frozen_string_literal: true

class MakeTicketTypeRequiredInBookings < ActiveRecord::Migration[8.1]
  def change
    change_column_null :bookings, :ticket_type_id, false
  end
end
