class CreateLibrarySources < ActiveRecord::Migration[8.1]
  def change
    create_table :library_sources do |t|
      t.string :path

      t.timestamps
    end
  end
end
