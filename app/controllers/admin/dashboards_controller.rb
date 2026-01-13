class Admin::DashboardsController < Admin::BaseController
  def show
    @user_count = User.count
    @movie_count = Movie.count
    @source_count = LibrarySource.count
  end
end
