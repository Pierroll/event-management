module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin!

    private

    def ensure_admin!
      unless current_user.admin?
        flash[:alert] = "Acceso restringido únicamente a administradores."
        redirect_to root_path
      end
    end
  end
end
