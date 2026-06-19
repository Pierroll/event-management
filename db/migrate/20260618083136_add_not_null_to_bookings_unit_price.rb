# frozen_string_literal: true

class AddNotNullToBookingsUnitPrice < ActiveRecord::Migration[8.1]
  def change
    change_column_null :bookings, :unit_price, false
  end
end
