class AddGeneratingSubtitleToMovies < ActiveRecord::Migration[8.1]
  def change
    add_column :movies, :generating_subtitle, :boolean
  end
end
