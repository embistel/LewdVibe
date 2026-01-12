class ChangeStudioAndDirectorToNullInMovies < ActiveRecord::Migration[8.1]
  def change
    change_column_null :movies, :studio_id, true
    change_column_null :movies, :director_id, true
  end
end
