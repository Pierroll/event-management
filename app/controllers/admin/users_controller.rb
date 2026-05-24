module Admin
  class UsersController < BaseController
    def index
      @users = User.includes(:roles).page(params[:page]).per(10)
    end

    def show
      @user = User.find(params[:id])
    end

    def edit
      @user = User.find(params[:id])
      @roles = Role.all
    end

    def update
      @user = User.find(params[:id])
      @roles = Role.all

      User.transaction do
        if @user.update(user_params)
          # Actualizar roles asignados
          role_ids = params[:user][:role_ids] || []
          # Asignar nuevos roles y limpiar anteriores
          @user.roles = Role.where(id: role_ids)
          redirect_to admin_user_path(@user), notice: "Usuario actualizado exitosamente."
        else
          render :edit, status: :unprocessable_entity
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      @user.errors.add(:base, "Error al actualizar roles: #{e.message}")
      render :edit, status: :unprocessable_entity
    end

    private

    def user_params
      params.require(:user).permit(:name, :email, :active)
    end
  end
end
