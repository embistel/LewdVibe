class DirectorsController < ApplicationController
  allow_unauthenticated_access
  def index
    @directors = Director.search(params[:query]).all.order(:name)
  end

  def show
    @director = Director.find(params[:id])
    @movies = @director.movies.includes(:studio)
  end
end
