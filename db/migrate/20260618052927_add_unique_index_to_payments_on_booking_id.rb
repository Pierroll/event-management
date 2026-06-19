# frozen_string_literal: true

class AddUniqueIndexToPaymentsOnBookingId < ActiveRecord::Migration[8.1]
  def up
    # Safeguard: remove any duplicate payments for the same booking
    # keeping only the most recent one per booking_id
    execute <<-SQL.squish
      DELETE FROM payments
      WHERE id IN (
        SELECT id FROM (
          SELECT id, ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY created_at DESC) AS rn
          FROM payments
        ) dupes
        WHERE rn > 1
      );
    SQL

    add_index :payments, :booking_id, unique: true, name: "index_payments_on_booking_id_unique"
  end

  def down
    remove_index :payments, name: "index_payments_on_booking_id_unique"
  end
end
