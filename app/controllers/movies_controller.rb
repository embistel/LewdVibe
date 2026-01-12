class MoviesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show poster ]
  def index
    @movies = Movie.search(params[:query]).includes(:studio, :director).order(created_at: :desc)
    # Basic pagination logic or load all if manageable. User didn't request explicit pagination, but it's good practice.
    # For now, just load all to keep it simple, or user can add gems later.
  end

  def show
    @movie = Movie.find(params[:id])
    @actors = @movie.actors
    @subtitles = find_subtitles(@movie.path)
  end

  def poster
    movie = Movie.find(params[:id])
    if movie.poster_path.present?
      if movie.poster_path.start_with?('http')
        redirect_to movie.poster_path, allow_other_host: true
      elsif File.exist?(movie.poster_path)
        send_file movie.poster_path, type: 'image/jpeg', disposition: 'inline'
      else
        head :not_found
      end
    else
      head :not_found
    end
  end

  def download_subtitle
    movie = Movie.find(params[:id])
    subtitles = find_subtitles(movie.path)
    lang = params[:lang] || "default"
    subtitle_path = subtitles[lang]
    
    if subtitle_path && File.exist?(subtitle_path)
      send_file subtitle_path, filename: File.basename(subtitle_path)
    else
      redirect_to movie_path(movie), alert: "Subtitle not found."
    end
  end

  private

  def find_subtitles(movie_file_path)
    return {} if movie_file_path.blank? || !File.exist?(movie_file_path)
    
    subtitles = {}
    base_filename = File.basename(movie_file_path, ".*")
    dir = File.dirname(movie_file_path)
    
    # Use Dir.entries to avoid globbing issues with bracketed paths [Prestige]
    begin
      entries = Dir.entries(dir)
    rescue Errno::ENOENT, Errno::ENOTDIR
      return {}
    end

    entries.each do |filename|
      next unless filename.downcase.end_with?(".srt")
      
      path = File.join(dir, filename)
      
      # Determine label
      if filename.downcase.include?(".ko.srt")
        subtitles["Korean"] = path
      elsif filename.downcase.include?(".en.srt")
        subtitles["English"] = path
      elsif filename.downcase.include?(".jp.srt")
        subtitles["Japanese"] = path
      elsif filename.downcase == "#{base_filename.downcase}.srt"
        subtitles["Default"] = path
      else
        # Try to extract language code from filename like "something.zh.srt"
        match = filename.match(/\.(\w{2})\.srt$/i)
        if match
          subtitles[match[1].upcase] = path
        else
          # If it's just some other srt, add it as a generic one
          # Remove .srt extension for the label
          label = filename.gsub(/\.srt$/i, "")
          subtitles[label] = path
        end
      end
    end
    
    subtitles
  end
end
