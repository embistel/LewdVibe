namespace :import do
  desc "Import NFO files from /mnt/diana/embistel/JavRegular"
  task nfo: :environment do
    NfoImporterService.new.call
  end

  desc "Clear all data and Re-import everything"
  task reset: :environment do
    puts "Clearing all data..."
    MovieActor.delete_all
    Movie.delete_all
    Actor.delete_all
    Studio.delete_all
    Director.delete_all
    
    puts "Starting fresh import..."
    Rake::Task["import:nfo"].invoke
  end
end
