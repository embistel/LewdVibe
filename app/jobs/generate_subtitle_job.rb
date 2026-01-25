class GenerateSubtitleJob < ApplicationJob
  queue_as :default

  VIDEO_EXTENSIONS = %w[.mp4 .mkv .avi .wmv .m4v .ts .flv .mov].freeze

  def perform(movie_id)
    movie = Movie.find(movie_id)
    nfo_path = movie.path
    return unless File.exist?(nfo_path)

    movie.update!(generating_subtitle: true)

    begin
      dir = File.dirname(nfo_path)
      base_name = File.basename(nfo_path, ".*")
      
      video_path = find_video_file(dir, base_name)
      unless video_path
        Rails.logger.error "[Whisper] Could not find video file for movie #{movie_id} at #{dir}"
        return
      end

      output_path = File.join(dir, "#{base_name}.ko.srt")
      
      # Check if subtitle already exists (extra safety)
      if File.exist?(output_path)
        Rails.logger.info "[Whisper] Subtitle already exists for #{movie_id}, skipping."
        return
      end

      python_executable = Rails.root.join("whisper_env/bin/python3")
      script_path = Rails.root.join("lib/python/generate_subtitles.py")

      command = "#{python_executable} #{script_path} #{Shellwords.escape(video_path)} #{Shellwords.escape(output_path)}"
      
      Rails.logger.info "[Whisper] Starting subtitle generation for movie #{movie_id}: #{video_path}"
      
      success = system(command)

      if success
        Rails.logger.info "[Whisper] Successfully generated subtitle for movie #{movie_id}"
      else
        Rails.logger.error "[Whisper] Failed to generate subtitle for movie #{movie_id}. Command exit code: #{$?.exitstatus}"
      end
    ensure
      movie.update!(generating_subtitle: false)
    end
  end

  private

  def find_video_file(dir, base_name)
    # 1. Try exact base name match
    VIDEO_EXTENSIONS.each do |ext|
      path = File.join(dir, "#{base_name}#{ext}")
      return path if File.exist?(path)
    end

    # 2. Try case-insensitive or partial if needed? 
    # For now, let's keep it simple. Usually they match.
    nil
  end
end
