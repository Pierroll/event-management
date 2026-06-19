# frozen_string_literal: true

class AddUniqueIndexToTicketTypesOnEventAndName < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :ticket_types, %i[event_id name], unique: true, algorithm: :concurrently
  end
end
