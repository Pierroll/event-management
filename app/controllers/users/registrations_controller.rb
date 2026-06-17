# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  def new
    build_resource({})
    resource.selected_role = params[:role] if params[:role].present?
    respond_with resource
  end

  def create
    build_resource(sign_up_params)
    resource.save
    yield resource if block_given?
    if resource.persisted?
      code = resource.generate_confirmation_code
      UserMailer.confirmation_code(resource, code).deliver_later
      session[:unconfirmed_email] = resource.email
      redirect_to new_confirmation_path, notice: t("confirmations.sent")
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end
end
