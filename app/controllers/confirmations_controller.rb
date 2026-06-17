# frozen_string_literal: true

class ConfirmationsController < ApplicationController
  # Allow unconfirmed users to access this controller
  skip_before_action :require_email_confirmation
  before_action :authenticate_user!, except: [:new, :verify]
  before_action :set_user, only: [:verify, :resend]

  def new
    @email = session[:unconfirmed_email] || current_user&.email
  end

  def create
    if current_user
      send_code(current_user)
    else
      redirect_to new_user_session_path, alert: t("confirmations.required")
    end
  end

  def resend
    if @user && ConfirmationCodeService.can_resend?(@user)
      code = @user.generate_confirmation_code
      UserMailer.confirmation_code(@user, code).deliver_later
      session[:unconfirmed_email] = @user.email
      redirect_to new_confirmation_path, notice: t("confirmations.sent")
    else
      redirect_to new_confirmation_path, alert: t("confirmations.resend_cooldown")
    end
  end

  def verify
    code = params[:confirmation_code]

    if code.blank?
      redirect_to new_confirmation_path, alert: t("confirmations.invalid")
      return
    end

    if @user&.confirm_with_code(code)
      sign_in(@user)
      redirect_to after_sign_in_path_for(@user), notice: t("confirmations.verified")
    else
      @user&.reload
      if @user && ConfirmationCodeService.code_expired?(@user)
        ConfirmationCodeService.invalidate(@user)
        redirect_to new_confirmation_path, alert: t("confirmations.expired")
      elsif @user && ConfirmationCodeService.attempts_exhausted?(@user)
        ConfirmationCodeService.invalidate(@user)
        redirect_to new_confirmation_path, alert: t("confirmations.exhausted")
      else
        redirect_to new_confirmation_path, alert: t("confirmations.invalid")
      end
    end
  end

  private

  def set_user
    @user = if session[:unconfirmed_email]
              User.find_by(email: session[:unconfirmed_email])
            else
              current_user
            end
  end

  def send_code(user)
    if ConfirmationCodeService.can_resend?(user)
      code = user.generate_confirmation_code
      UserMailer.confirmation_code(user, code).deliver_later
      session[:unconfirmed_email] = user.email
      redirect_to new_confirmation_path, notice: t("confirmations.sent")
    else
      redirect_to new_confirmation_path, alert: t("confirmations.resend_cooldown")
    end
  end
end
