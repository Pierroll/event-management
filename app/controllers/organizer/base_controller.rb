module Organizer
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_organizer!

    private

    def ensure_organizer!
      unless current_user.organizer? || current_user.admin?
        flash[:alert] = "Acceso restringido únicamente a organizadores."
        redirect_to root_path
      end
    end
  end
end
