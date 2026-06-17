# frozen_string_literal: true

class AddConfirmationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_code, :string
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :confirmation_attempts, :integer, default: 0
  end
end
