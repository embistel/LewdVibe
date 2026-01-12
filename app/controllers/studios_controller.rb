class StudiosController < ApplicationController
  allow_unauthenticated_access
  def index
    @studios = Studio.search(params[:query]).all.order(:name)
  end

  def show
    @studio = Studio.find(params[:id])
    @movies = @studio.movies.includes(:director)
  end
end
