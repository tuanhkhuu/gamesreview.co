class CreateGameGenres < ActiveRecord::Migration[8.1]
  def change
    create_table :game_genres do |t|
      t.references :game, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true

      t.timestamps
    end
    add_index :game_genres, [ :game_id, :genre_id ], unique: true
  end
end
