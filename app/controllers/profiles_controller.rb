class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    if current_user.dev?
      skip_authorization
      redirect_to developers_portal_path
      return
    end

    @user = current_user
    authorize @user, policy_class: ProfilePolicy
    @favorite_events = @user.favorite_events.includes(:category, :event_images)
  end

  def edit
    @user = current_user
    authorize @user, policy_class: ProfilePolicy
  end

  def update
    @user = current_user
    authorize @user, policy_class: ProfilePolicy
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Perfil actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email)
  end
end
