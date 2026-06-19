# frozen_string_literal: true

class MakeTicketTypeRequiredInBookings < ActiveRecord::Migration[8.1]
  def up
    # 1. Backfill: asociar reservas huérfanas al primer ticket_type de su evento
    execute <<~SQL
      UPDATE bookings
      SET ticket_type_id = (
        SELECT id FROM ticket_types
        WHERE ticket_types.event_id = bookings.event_id
        ORDER BY position ASC, id ASC
        LIMIT 1
      )
      WHERE ticket_type_id IS NULL;
    SQL

    # 2. Eliminar reservas que no se pudieron asociar (por ejemplo, si el evento no tiene tipos de ticket)
    execute "DELETE FROM bookings WHERE ticket_type_id IS NULL;"

    # 3. Aplicar la restricción de NOT NULL
    change_column_null :bookings, :ticket_type_id, false
  end

  def down
    change_column_null :bookings, :ticket_type_id, true
  end
end
