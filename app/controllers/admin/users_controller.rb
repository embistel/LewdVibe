class Admin::UsersController < Admin::BaseController
  def index
    @users = User.all.order(created_at: :desc)
  end

  def destroy
    @user = User.find(params[:id])
    if @user.email_address == "root"
      redirect_to admin_users_path, alert: "Root administrator cannot be deleted."
    elsif @user == Current.session.user
      redirect_to admin_users_path, alert: "You cannot delete yourself from the admin panel."
    else
      @user.destroy
      redirect_to admin_users_path, notice: "User deleted successfully."
    end
  end
end
