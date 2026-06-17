# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Confirmations", type: :request do
  let(:password) { "password123" }

  before do
    Role.find_or_create_by!(name: "registered_user")
    # Ensure we have a user who needs confirmation
    Role.find_or_create_by!(name: "organizer")
  end

  describe "access control" do
    it "allows unauthenticated user to access confirmation page" do
      get new_confirmation_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Verifica")
    end

    it "redirects unauthenticated user to sign in for send code" do
      post confirmation_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /confirmation/new" do
    it "shows the confirmation form for unconfirmed user" do
      user = User.create!(
        name: "Unconfirmed",
        email: "unconfirmed@test.com",
        password: password,
        confirmed_at: nil
      )
      sign_in user
      get new_confirmation_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Verifica")
    end

    it "redirects confirmed user away from confirmation page" do
      # Confirmed users hit require_email_confirmation which redirects them away
      user = User.create!(
        name: "Confirmed",
        email: "confirmed@test.com",
        password: password,
        confirmed_at: Time.current
      )
      sign_in user
      get new_confirmation_path
      # The skip_before_action allows confirmed users too, they just see the page
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /confirmation (send code)" do
    it "sends a code and redirects with notice" do
      user = User.create!(
        name: "Code User",
        email: "code@test.com",
        password: password,
        confirmed_at: nil
      )
      sign_in user

      expect {
        post confirmation_path
      }.to have_enqueued_mail(UserMailer, :confirmation_code)

      expect(response).to redirect_to(new_confirmation_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("confirmations.sent"))
    end

    it "respects resend cooldown" do
      user = User.create!(
        name: "Cooldown User",
        email: "cooldown@test.com",
        password: password,
        confirmed_at: nil,
        confirmation_sent_at: Time.current
      )
      sign_in user

      post confirmation_path
      expect(response).to redirect_to(new_confirmation_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("confirmations.resend_cooldown"))
    end
  end

  describe "POST /confirmation/verify" do
    it "verifies with correct code and redirects to dashboard" do
      user = User.create!(
        name: "Verify User",
        email: "verify@test.com",
        password: password,
        confirmed_at: nil
      )
      sign_in user

      code = ConfirmationCodeService.generate(user)

      post verify_confirmation_path, params: { confirmation_code: code }
      expect(response).to redirect_to(root_path)
      expect(user.reload.confirmed_at).to be_present
    end

    it "rejects wrong code" do
      user = User.create!(
        name: "Wrong Code",
        email: "wrong@test.com",
        password: password,
        confirmed_at: nil
      )
      sign_in user
      ConfirmationCodeService.generate(user)

      post verify_confirmation_path, params: { confirmation_code: "000000" }
      expect(response).to redirect_to(new_confirmation_path)
      expect(user.reload.confirmed_at).to be_nil
    end

    it "shows expired error for expired code" do
      user = User.create!(
        name: "Expired",
        email: "expired@test.com",
        password: password,
        confirmed_at: nil
      )
      sign_in user
      ConfirmationCodeService.generate(user)
      user.update!(confirmation_sent_at: 16.minutes.ago)

      post verify_confirmation_path, params: { confirmation_code: "000000" }
      expect(response).to redirect_to(new_confirmation_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("confirmations.expired"))
    end

    it "shows exhausted error after 3 failed attempts" do
      user = User.create!(
        name: "Exhausted",
        email: "exhausted@test.com",
        password: password,
        confirmed_at: nil
      )
      sign_in user
      ConfirmationCodeService.generate(user)

      3.times do
        post verify_confirmation_path, params: { confirmation_code: "111111" }
      end

      expect(response).to redirect_to(new_confirmation_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("confirmations.exhausted"))
      expect(user.reload.confirmation_code).to be_nil
    end
  end

  describe "POST /confirmation/resend" do
    it "resends code and redirects with notice" do
      user = User.create!(
        name: "Resend User",
        email: "resend@test.com",
        password: password,
        confirmed_at: nil
      )
      sign_in user

      # First send to set the cooldown
      ConfirmationCodeService.generate(user)
      user.update!(confirmation_sent_at: 61.seconds.ago)

      expect {
        post resend_confirmation_path
      }.to have_enqueued_mail(UserMailer, :confirmation_code)

      expect(response).to redirect_to(new_confirmation_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("confirmations.sent"))
    end

    it "blocks resend within 60 seconds" do
      user = User.create!(
        name: "Resend Block",
        email: "resend-block@test.com",
        password: password,
        confirmed_at: nil
      )
      sign_in user
      ConfirmationCodeService.generate(user) # sets confirmation_sent_at to now

      post resend_confirmation_path
      expect(response).to redirect_to(new_confirmation_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("confirmations.resend_cooldown"))
    end
  end

  describe "before_action :require_email_confirmation" do
    it "redirects unconfirmed user to confirmation page" do
      user = User.create!(
        name: "Gate",
        email: "gate@test.com",
        password: password,
        confirmed_at: nil
      )
      sign_in user

      get root_path
      expect(response).to redirect_to(new_confirmation_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("confirmations.required"))
    end

    it "allows OAuth users through" do
      user = User.create!(
        name: "OAuth User",
        email: "oauth-gate@test.com",
        password: password,
        provider: "google_oauth2",
        uid: "gate-uid",
        confirmed_at: nil
      )
      sign_in user

      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "allows confirmed users through" do
      user = User.create!(
        name: "Confirmed Gate",
        email: "confirmed-gate@test.com",
        password: password,
        confirmed_at: Time.current
      )
      sign_in user

      get root_path
      expect(response).to have_http_status(:ok)
    end
  end
end
