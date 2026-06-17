# frozen_string_literal: true

class BackfillExistingUsersConfirmedAt < ActiveRecord::Migration[8.1]
  def up
    User.where(confirmed_at: nil).update_all(confirmed_at: Time.current)
  end

  def down
    # No revert — we don't track who was originally unconfirmed
  end
end
