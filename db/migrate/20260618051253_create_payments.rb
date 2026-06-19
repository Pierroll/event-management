# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :booking, null: false, foreign_key: true
      t.string :provider, null: false, default: "mock"
      t.string :provider_charge_id
      t.integer :status, default: 0
      t.jsonb :raw_response, default: {}

      t.timestamps
    end

    add_index :payments, :provider_charge_id, unique: true, where: "provider_charge_id IS NOT NULL"
  end
end
