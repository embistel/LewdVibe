class Admin::BaseController < ApplicationController
  before_action :ensure_admin

  private

  def ensure_admin
    unless authenticated? && Current.session.user.admin?
      redirect_to root_path, alert: "You are not authorized to access this area."
    end
  end
end
