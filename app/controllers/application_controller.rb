class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :require_email_confirmation

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :selected_role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_up_path_for(resource)
    new_confirmation_path
  end

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_dashboard_path
    elsif resource.organizer?
      organizer_events_path
    else
      root_path
    end
  end

  private

  def require_email_confirmation
    return unless current_user
    return if current_user.confirmed?

    redirect_to new_confirmation_path, alert: t("confirmations.required")
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    query = exception.query

    Rails.logger.warn "[PUNDIT] Not authorized: #{policy_name}##{query} for user##{current_user&.id}"

    flash[:alert] = t("pundit.errors.not_authorized")
    redirect_to(request.referrer || root_path)
  end
end
