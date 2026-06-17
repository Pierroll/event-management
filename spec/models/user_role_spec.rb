require 'rails_helper'

RSpec.describe UserRole, type: :model do
  let(:user) { User.create!(name: "Test", email: "test@ur.com", password: "password123") }
  let(:role) { Role.create!(name: "test_role") }

  describe "validations" do
    it "is valid with a user and role" do
      user_role = UserRole.new(user: user, role: role)
      expect(user_role).to be_valid
    end

    it "enforces uniqueness of user_id scoped to role_id" do
      UserRole.create!(user: user, role: role)
      duplicate = UserRole.new(user: user, role: role)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("ya está en uso")
    end

    it "allows the same user to have different roles" do
      other_role = Role.create!(name: "other_role")
      UserRole.create!(user: user, role: role)
      duplicate = UserRole.new(user: user, role: other_role)
      expect(duplicate).to be_valid
    end

    it "allows the same role for different users" do
      other_user = User.create!(name: "Other", email: "other@ur.com", password: "password123")
      UserRole.create!(user: user, role: role)
      duplicate = UserRole.new(user: other_user, role: role)
      expect(duplicate).to be_valid
    end
  end

  describe "associations" do
    it "belongs to user" do
      user_role = UserRole.new(user: user, role: role)
      expect(user_role.user).to eq(user)
    end

    it "belongs to role" do
      user_role = UserRole.new(user: user, role: role)
      expect(user_role.role).to eq(role)
    end

    it "belongs to assigned_by (optional)" do
      admin = User.create!(name: "Admin", email: "admin@ur.com", password: "password123")
      user_role = UserRole.new(user: user, role: role, assigned_by: admin)
      expect(user_role.assigned_by).to eq(admin)
    end
  end
end
