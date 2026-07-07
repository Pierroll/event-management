module Developers
  class PortalsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_developer!
    after_action :skip_authorization

    def show
      # Vista del portal (automática)
    end

    def regenerate_api_token
      current_user.regenerate_api_token
      redirect_to developers_portal_path, notice: "Tu API Key ha sido regenerada por seguridad."
    end

    private

    def authorize_developer!
      unless current_user.dev?
        redirect_to root_path, alert: "No tienes acceso al Portal de Desarrolladores."
      end
    end
  end
end
