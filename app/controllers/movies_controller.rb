class MoviesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show poster subtitles_data ]
  def index
    @movies = Movie.search(params[:query]).includes(:studio, :director).order(created_at: :desc)
    # Basic pagination logic or load all if manageable. User didn't request explicit pagination, but it's good practice.
    # For now, just load all to keep it simple, or user can add gems later.
  end

  def show
    @movie = Movie.find(params[:id])
    @actors = @movie.actors
    @subtitles = find_subtitles(@movie.path)
    
    # Storyboard data
    @storyboard_images = find_storyboard_images(@movie.path)
    
    # Robustly find initial language
    @current_lang = if @subtitles.key?("Korean")
      "Korean"
    elsif @subtitles.key?("Default")
      "Default"
    else
      @subtitles.keys.first
    end

    Rails.logger.info "[Storyboard] Movie: #{@movie.id}, Current Lang: #{@current_lang}, Subtitles found: #{@subtitles.keys}"

    primary_subtitle_path = @subtitles[@current_lang]
    @parsed_subtitles = primary_subtitle_path ? parse_srt(primary_subtitle_path) : []
    
    Rails.logger.info "[Storyboard] Parsed subtitles count: #{@parsed_subtitles.size}"
  end

  def subtitles_data
    movie = Movie.find(params[:id])
    subtitles = find_subtitles(movie.path)
    lang = params[:lang]
    subtitle_path = subtitles[lang] || subtitles.find { |k, v| k.downcase == lang.to_s.downcase }&.last
    
    Rails.logger.info "[Storyboard] Subtitles Data Request - Lang: #{lang}, Found Path: #{subtitle_path}"

    if subtitle_path && File.exist?(subtitle_path)
      render json: parse_srt(subtitle_path)
    else
      render json: []
    end
  end

  def storyboard_image
    movie = Movie.find(params[:id])
    filename = params[:filename]
    story_dir = File.join(File.dirname(movie.path), "Story")
    image_path = File.join(story_dir, filename)

    if File.exist?(image_path) && File.realpath(image_path).start_with?(File.realpath(story_dir))
      send_file image_path, type: 'image/jpeg', disposition: 'inline'
    else
      head :not_found
    end
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
    lang = params[:lang]
    
    # Try find by exact match, then case-insensitive match
    subtitle_path = subtitles[lang] || subtitles.find { |k, v| k.to_s.downcase == lang.to_s.downcase }&.last
    
    # Fallback if still not found
    subtitle_path ||= subtitles.values.first if lang.blank? || lang == "default"
    
    Rails.logger.info "[Storyboard] Download Subtitle Request - Lang: #{lang}, Found Path: #{subtitle_path}"

    if subtitle_path && File.exist?(subtitle_path)
      send_file subtitle_path, filename: File.basename(subtitle_path)
    else
      redirect_to movie_path(movie), alert: "Subtitle not found."
    end
  end

  private

  def find_storyboard_images(movie_file_path)
    return [] if movie_file_path.blank?
    story_dir = File.join(File.dirname(movie_file_path), "Story")
    return [] unless Dir.exist?(story_dir)

    images = []
    begin
      entries = Dir.entries(story_dir)
    rescue
      return []
    end

    entries.each do |filename|
      next unless filename.downcase.end_with?(".jpg")
      
      # Regex to match MovieName.HH-MM-SS.mmm.JPG
      # Example: AARM-082.00-10-06.870.JPG
      match = filename.match(/\.(\d{2})-(\d{2})-(\d{2})\.(\d{3})\.JPG$/i)
      if match
        h, m, s, ms = match.captures.map(&:to_i)
        seconds = h * 3600 + m * 60 + s + ms / 1000.0
        images << { time: seconds, filename: filename }
      end
    end
    images.sort_by { |i| i[:time] }
  end

  def parse_srt(srt_path)
    return [] unless File.exist?(srt_path)
    
    parsed = []
    begin
      content = File.read(srt_path, encoding: 'UTF-8').gsub("\r\n", "\n")
    rescue
      begin
        content = File.read(srt_path, encoding: 'ISO-8859-1').gsub("\r\n", "\n")
      rescue
        content = ""
      end
    end
    
    # Split by one or more blank lines
    blocks = content.split(/\n\n+/)
    blocks.each do |block|
      lines = block.strip.split("\n")
      # Find the line that looks like a timestamp: 00:00:00,000 --> 00:00:00,000
      time_line_idx = lines.find_index { |l| l.include?("-->") }
      next unless time_line_idx
      
      time_match = lines[time_line_idx].match(/(\d{2}:\d{2}:\d{2}[,. ]\d{3}) --> (\d{2}:\d{2}:\d{2}[,. ]\d{3})/)
      if time_match
        start_time = srt_time_to_seconds(time_match[1])
        end_time = srt_time_to_seconds(time_match[2])
        # Text starts after the time line
        text = lines[(time_line_idx + 1)..-1].join("<br>").strip
        parsed << { start: start_time, end: end_time, text: text }
      end
    end
    parsed
  rescue => e
    Rails.logger.error "[Storyboard] Error parsing SRT: #{e.message}"
    []
  end

  def srt_time_to_seconds(time_str)
    # Format: HH:MM:SS,mmm or HH:MM:SS.mmm
    match = time_str.match(/(\d{2}):(\d{2}):(\d{2})[,. ](\d{3})/)
    return 0 unless match
    h, m, s, ms = match.captures.map(&:to_i)
    h * 3600 + m * 60 + s + ms / 1000.0
  end

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
