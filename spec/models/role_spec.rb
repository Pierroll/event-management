require 'rails_helper'

RSpec.describe Role, type: :model do
  describe "validations" do
    it "is valid with a unique name" do
      role = Role.new(name: "moderator")
      expect(role).to be_valid
    end

    it "requires a name" do
      role = Role.new(name: nil)
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("no puede estar en blanco")
    end

    it "requires a unique name" do
      Role.create!(name: "admin")
      role = Role.new(name: "admin")
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("ya está en uso")
    end
  end

  describe "associations" do
    it "has many user_roles" do
      role = Role.create!(name: "editor")
      user = User.create!(name: "Test", email: "test@role.com", password: "password123")
      user.roles << role

      expect(role.users).to include(user)
    end

    it "destroys dependent user_roles when destroyed" do
      role = Role.create!(name: "temp_role")
      user = User.create!(name: "Temp", email: "temp@role.com", password: "password123")
      user.roles << role

      expect { role.destroy }.to change { UserRole.count }.by(-1)
    end
  end
end
