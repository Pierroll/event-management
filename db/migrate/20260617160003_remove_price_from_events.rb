# frozen_string_literal: true

class RemovePriceFromEvents < ActiveRecord::Migration[8.1]
  def change
    remove_column :events, :price, :decimal
  end
end
