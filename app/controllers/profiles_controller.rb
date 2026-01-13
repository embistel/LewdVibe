class ProfilesController < ApplicationController
  before_action :set_user

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to profile_path, notice: "Account updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.admin?
      redirect_to profile_path, alert: "Administrators cannot delete their own accounts from here."
    else
      @user.destroy
      terminate_session
      redirect_to root_path, notice: "Your account has been deleted."
    end
  end

  private

  def set_user
    @user = Current.session.user
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
