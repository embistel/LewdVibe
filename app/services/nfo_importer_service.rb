class NfoImporterService
  require 'nokogiri'

  def call
    base_paths = LibrarySource.pluck(:path)
    
    # 1. Clean up movies that are no longer in any registered source
    all_movies = Movie.all
    all_movies.each do |movie|
      is_managed = base_paths.any? { |bp| movie.path.start_with?(bp) }
      unless is_managed && File.exist?(movie.path)
        movie.destroy
        puts "Deleted orphan movie: #{movie.title}"
      end
    end

    # 2. Import/Update movies from base paths
    base_paths.each do |base_path|
      puts "Starting import from #{base_path}..."
      unless Dir.exist?(base_path)
        puts "Directory does not exist: #{base_path}"
        next
      end

      files = Dir.glob(File.join(base_path, '**', '*.nfo'))
      puts "Found #{files.count} NFO files in #{base_path}."

      files.each do |file_path|
        import_nfo(file_path)
      end
      puts "\nImport for #{base_path} complete."
    end
    puts "All imports complete."
  end

  private

  def import_nfo(file_path)
    doc = File.open(file_path) { |f| Nokogiri::XML(f) }
    
    # Basic Check
    return unless doc.at_xpath('//movie')

    # Extract Data
    title = doc.at_xpath('//movie/title')&.text
    original_title = doc.at_xpath('//movie/originaltitle')&.text
    plot = doc.at_xpath('//movie/plot')&.text
    # outline = doc.at_xpath('//movie/outline')&.text
    year_text = doc.at_xpath('//movie/year')&.text
    premiered_text = doc.at_xpath('//movie/premiered')&.text
    studio_name = doc.at_xpath('//movie/studio')&.text
    director_name = doc.at_xpath('//movie/director')&.text
    
    poster_node = doc.xpath('//movie/thumb').find { |t| t.text.match?(/poster|cover/) } || doc.at_xpath('//movie/thumb')
    poster_val = poster_node&.text
    
    poster_path = nil
    if poster_val.present?
      if poster_val.start_with?('http')
        poster_path = poster_val
      else
        # Try finding local file relative to NFO
        dir = File.dirname(file_path)
        potential_path = File.join(dir, poster_val)
        if File.exist?(potential_path)
          poster_path = potential_path
        else
          # Try common names if thumb tag is just a type
          ['poster.jpg', 'cover.jpg', 'folder.jpg'].each do |name|
            p = File.join(dir, name)
            if File.exist?(p)
              poster_path = p
              break
            end
          end
        end
      end
    end

    # Date parsing
    release_date = nil
    if premiered_text.present?
      begin
        release_date = Date.parse(premiered_text)
      rescue
        release_date = nil
      end
    end

    # Create Associations
    studio = Studio.find_or_create_by(name: studio_name.strip) if studio_name.present?
    director = Director.find_or_create_by(name: director_name.strip) if director_name.present?

    # Create Movie
    movie = Movie.find_or_initialize_by(path: file_path)
    movie.update!(
      title: title&.strip || original_title&.strip || File.basename(file_path, '.nfo'),
      plot: plot&.strip,
      poster_path: poster_path,
      release_date: release_date,
      studio: studio,
      director: director
    )

    # Actors
    doc.xpath('//movie/actor').each do |actor_node|
      name = actor_node.at_xpath('name')&.text
      next if name.blank?
      
      thumb = actor_node.at_xpath('thumb')&.text
      role = actor_node.at_xpath('role')&.text

      actor = Actor.find_or_create_by(name: name)
      # Update thumb only if missing or update logic (skip for now to avoid overhead)
      actor.update(thumb_path: thumb) if thumb.present? && actor.thumb_path.blank?

      MovieActor.find_or_create_by(movie: movie, actor: actor, role: role)
    end
    
    print "."
  end
end
