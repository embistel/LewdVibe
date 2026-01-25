class SubtitleGeneratorService
  def call
    count = 0
    Movie.find_each do |movie|
      if needs_subtitle?(movie)
        GenerateSubtitleJob.perform_later(movie.id)
        count += 1
      end
    end
    count
  end

  private

  def needs_subtitle?(movie)
    return false if movie.path.blank? || !File.exist?(movie.path)
    
    dir = File.dirname(movie.path)
    # Check if any .srt files exist in the directory
    # We could be more specific (matching base name), but usually if there is AN srt, we don't auto-gen.
    # Actually, let's be more specific: look for base_name.srt or base_name.ko.srt etc.
    
    base_name = File.basename(movie.path, ".*")
    begin
      entries = Dir.entries(dir)
      # Does any .srt file start with the same base name?
      has_srt = entries.any? { |e| e.downcase.start_with?(base_name.downcase) && e.downcase.end_with?(".srt") }
      !has_srt
    rescue
      false
    end
  end
end
