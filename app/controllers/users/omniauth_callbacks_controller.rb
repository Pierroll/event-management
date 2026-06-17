# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :require_email_confirmation, raise: false

    # Store role in session then redirect to Google OAuth
    def authorize_with_role
      session[:pending_role] = params[:selected_role]
      redirect_to user_google_oauth2_omniauth_authorize_path
    end

    def google_oauth2
      auth = request.env["omniauth.auth"]

      unless auth.info.email_verified
        redirect_to new_user_session_path, alert: t("devise.omniauth.email_not_verified")
        return
      end

      @user = User.from_google(auth, role_name: session.delete(:pending_role) || "registered_user")

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
      else
        redirect_to new_user_session_path,
                    alert: t("devise.omniauth.failure", kind: "Google", reason: @user.errors.full_messages.to_sentence)
      end
    end

    def failure
      redirect_to new_user_session_path,
                  alert: t("devise.omniauth.failure", kind: "Google", reason: "Error de autenticación")
    end
  end
end
