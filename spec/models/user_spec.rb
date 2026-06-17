require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      user = User.new(name: "Juan", email: "juan@test.com", password: "password123")
      expect(user).to be_valid
    end

    it "requires a name" do
      user = User.new(name: nil, email: "test@test.com", password: "password123")
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("no puede estar en blanco")
    end

    it "requires a unique email" do
      User.create!(name: "Uno", email: "dupe@test.com", password: "password123")
      user = User.new(name: "Dos", email: "dupe@test.com", password: "password123")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("ya está en uso")
    end
  end

  describe "defaults" do
    it "is active by default" do
      user = User.new(name: "Test", email: "test@default.com", password: "password123")
      expect(user.active).to be true
    end
  end

  describe "role helpers" do
    let(:admin_role) { Role.create!(name: "admin") }
    let(:org_role) { Role.create!(name: "organizer") }
    let(:user_role) { Role.create!(name: "registered_user") }

    it "#admin? returns true if user has admin role" do
      user = User.create!(name: "Admin", email: "admin@helper.com", password: "password123")
      user.roles << admin_role
      expect(user.admin?).to be true
    end

    it "#organizer? returns true if user has organizer role" do
      user = User.create!(name: "Org", email: "org@helper.com", password: "password123")
      user.roles << org_role
      expect(user.organizer?).to be true
    end

    it "#registered_user? returns true if user has registered_user role" do
      user = User.create!(name: "User", email: "user@helper.com", password: "password123")
      user.roles << user_role
      expect(user.registered_user?).to be true
    end

    it "#role? checks by role name" do
      user = User.create!(name: "Test", email: "test@helper.com", password: "password123")
      user.roles << admin_role
      expect(user.role?("admin")).to be true
      expect(user.role?("organizer")).to be false
    end
  end

  describe "callbacks" do
    before do
      Role.find_or_create_by!(name: "registered_user")
    end

    it "assigns registered_user role by default on create" do
      user = User.create!(name: "New", email: "new@cb.com", password: "password123")
      expect(user.registered_user?).to be true
    end

    it "assigns the selected role when provided" do
      Role.find_or_create_by!(name: "organizer")
      user = User.create!(
        name: "Org",
        email: "org@cb.com",
        password: "password123",
        selected_role: "organizer"
      )
      expect(user.organizer?).to be true
    end
  end

  describe "associations" do
    it "has many organized events" do
      user = User.create!(name: "Org", email: "org@assoc.com", password: "password123")
      expect(user).to respond_to(:organized_events)
    end

    it "has many comments" do
      user = User.create!(name: "User", email: "user@assoc.com", password: "password123")
      expect(user).to respond_to(:comments)
    end
  end

  describe ".from_google" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "google-uid-1",
        info: {
          email: "google@example.com",
          name: "Google User",
          email_verified: true
        }
      )
    end

    it "creates a new user when email does not exist" do
      user = User.from_google(auth)
      expect(user).to be_persisted
      expect(user.email).to eq("google@example.com")
      expect(user.name).to eq("Google User")
      expect(user.provider).to eq("google_oauth2")
      expect(user.uid).to eq("google-uid-1")
    end

    it "sets confirmed_at for OAuth users" do
      user = User.from_google(auth)
      expect(user.confirmed_at).to be_present
    end

    it "links existing user by email" do
      existing = User.create!(
        name: "Existing",
        email: "google@example.com",
        password: "password123"
      )
      linked = User.from_google(auth)
      expect(linked.id).to eq(existing.id)
      expect(linked.reload.provider).to eq("google_oauth2")
      expect(linked.uid).to eq("google-uid-1")
    end

    it "raises on invalid data" do
      bad_auth = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "bad-uid",
        info: { email: "", name: "", email_verified: true }
      )
      expect { User.from_google(bad_auth) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#confirmed?" do
    it "returns true if confirmed_at is present" do
      user = User.create!(name: "C", email: "c@t.com", password: "password123", confirmed_at: Time.current)
      expect(user.confirmed?).to be true
    end

    it "returns true if provider is present (OAuth user)" do
      user = User.create!(name: "O", email: "o@t.com", password: "password123", provider: "google_oauth2", uid: "x")
      expect(user.confirmed?).to be true
    end

    it "returns false if neither confirmed_at nor provider" do
      user = User.create!(name: "U", email: "u@t.com", password: "password123", confirmed_at: nil, provider: nil)
      expect(user.confirmed?).to be false
    end
  end

  describe "#confirm_with_code" do
    it "delegates to ConfirmationCodeService.verify" do
      user = User.create!(name: "CW", email: "cw@t.com", password: "password123")
      allow(ConfirmationCodeService).to receive(:verify).with(user, "123456").and_return(true)
      result = user.confirm_with_code("123456")
      expect(result).to be true
      expect(ConfirmationCodeService).to have_received(:verify).with(user, "123456")
    end
  end

  describe "#generate_confirmation_code" do
    it "delegates to ConfirmationCodeService.generate" do
      user = User.create!(name: "GC", email: "gc@t.com", password: "password123")
      allow(ConfirmationCodeService).to receive(:generate).with(user).and_return("654321")
      code = user.generate_confirmation_code
      expect(code).to eq("654321")
      expect(ConfirmationCodeService).to have_received(:generate).with(user)
    end
  end
end
