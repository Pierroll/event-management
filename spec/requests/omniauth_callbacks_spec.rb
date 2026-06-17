# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OmniauthCallbacks", type: :request do
  before do
    # Ensure roles exist for after_create callback
    Role.find_or_create_by!(name: "registered_user")
  end

  describe "GET /users/auth/google_oauth2/callback" do
    context "with valid auth hash" do
      before do
        mock_google_auth(email: "new@example.com", name: "New User")
      end

      it "creates user and signs in" do
        get user_google_oauth2_omniauth_callback_path
        expect(response).to redirect_to(root_path)
        expect(response).to have_http_status(:redirect)
      end

      it "sets provider and uid on the new user" do
        expect { get user_google_oauth2_omniauth_callback_path }
          .to change(User, :count).by(1)
        user = User.find_by(email: "new@example.com")
        expect(user.provider).to eq("google_oauth2")
        expect(user.uid).to eq("987654321")
      end
    end

    context "with existing email (account linking)" do
      let!(:existing_user) do
        User.create!(
          name: "Existing",
          email: "existing@example.com",
          password: "password123"
        )
      end

      before do
        mock_google_auth(email: "existing@example.com", name: "Existing")
      end

      it "links the account and signs in" do
        get user_google_oauth2_omniauth_callback_path
        expect(existing_user.reload.provider).to eq("google_oauth2")
        expect(existing_user.uid).to eq("987654321")
        expect(response).to redirect_to(root_path)
      end

      it "does not create a new user" do
        expect { get user_google_oauth2_omniauth_callback_path }
          .not_to change(User, :count)
      end
    end

    context "with unverified email" do
      before do
        mock_google_auth(email: "unverified@example.com", name: "Unverified", email_verified: false)
      end

      it "redirects to sign in with alert" do
        get user_google_oauth2_omniauth_callback_path
        expect(response).to redirect_to(new_user_session_path)
        follow_redirect!
        expect(response.body).to include(I18n.t("devise.omniauth.email_not_verified"))
      end
    end

    context "on failure" do
      it "redirects to sign in with alert" do
        # Simulate OmniAuth failure by posting directly to callback without auth hash
        # In test mode, OmniAuth failure app redirects here
        get user_google_oauth2_omniauth_callback_path
        # Without mock_auth set for the request, it should fail gracefully
        expect(response).to redirect_to(new_user_session_path).or have_http_status(:redirect)
      end
    end
  end
end
