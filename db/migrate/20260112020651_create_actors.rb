class CreateActors < ActiveRecord::Migration[8.1]
  def change
    create_table :actors do |t|
      t.string :name
      t.string :thumb_path

      t.timestamps
    end
  end
end
