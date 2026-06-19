# frozen_string_literal: true

module UserHelpers
  def create_user(overrides = {})
    defaults = {
      name: "Test User",
      email: "test#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      selected_role: "registered_user"
    }
    User.create!(defaults.merge(overrides))
  end

  def create_organizer(overrides = {})
    create_user(overrides.reverse_merge(selected_role: "organizer"))
  end

  def create_admin(overrides = {})
    create_user(overrides.reverse_merge(selected_role: "admin"))
  end
end

RSpec.configure do |config|
  config.include UserHelpers
end
