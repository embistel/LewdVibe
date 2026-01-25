class Admin::SourcesController < Admin::BaseController
  def index
    @sources = LibrarySource.all
    @new_source = LibrarySource.new
    @total_movies = Movie.count
    @generating_movie = Movie.find_by(generating_subtitle: true)
    if @generating_movie
      @generating_movies = Movie.where(generating_subtitle: true).where.not(id: @generating_movie.id)
    else
      @generating_movies = Movie.where(generating_subtitle: true)
    end
  end

  def create
    @source = LibrarySource.new(source_params)
    if @source.save
      redirect_to admin_sources_path, notice: "Source added successfully."
    else
      @sources = LibrarySource.all
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @source = LibrarySource.find(params[:id])
    path_to_remove = @source.path
    
    # Count before deletion for the notice
    removed_count = Movie.where("path LIKE ?", "#{path_to_remove}%").count
    
    # Delete all movies that belong to this source path
    Movie.where("path LIKE ?", "#{path_to_remove}%").destroy_all
    
    @source.destroy
    redirect_to admin_sources_path, notice: "Source removed. #{removed_count} movies have been deleted from the library."
  end

  def sync
    # Clear existing data if re-building from scratch is desired?
    # User said "re-construct library based on media folders"
    # For now, let's just trigger the importer service.
    NfoImporterService.new.call
    redirect_to admin_sources_path, notice: "Library sync started."
  end

  def generate_subtitles
    count = SubtitleGeneratorService.new.call
    redirect_to admin_sources_path, notice: "Queued #{count} subtitle generation jobs in the background."
  end

  private

  def source_params
    params.require(:library_source).permit(:path)
  end
end
