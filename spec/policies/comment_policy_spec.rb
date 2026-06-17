require 'rails_helper'

RSpec.describe CommentPolicy, type: :policy do
  subject { described_class }

  let(:user) { User.create!(name: "User", email: "user@test.com", password: "password123", active: true) }
  let(:other_user) { User.create!(name: "Other", email: "other@test.com", password: "password123", active: true) }
  let(:admin) do
    User.create!(name: "Admin", email: "admin@test.com", password: "password123", active: true).tap do |u|
      u.roles << Role.find_or_create_by!(name: "admin")
    end
  end
  let(:guest) { nil }
  let(:comment) { Comment.new(user: user) }

  permissions :create? do
    it "allows authenticated users" do
      expect(subject).to permit(user, Comment.new)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, Comment.new)
    end
  end

  permissions :destroy? do
    it "allows admin to delete any comment" do
      expect(subject).to permit(admin, comment)
    end

    it "allows the comment author to delete their own comment" do
      expect(subject).to permit(user, comment)
    end

    it "denies other users" do
      expect(subject).not_to permit(other_user, comment)
    end

    it "denies guests" do
      expect(subject).not_to permit(guest, comment)
    end
  end
end
