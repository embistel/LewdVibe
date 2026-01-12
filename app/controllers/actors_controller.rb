class ActorsController < ApplicationController
  allow_unauthenticated_access
  def index
    @actors = Actor.search(params[:query]).order(:name)
  end

  def show
    @actor = Actor.find(params[:id])
    @movies = @actor.movies.includes(:studio, :director)
  end
end
