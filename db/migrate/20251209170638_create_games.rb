class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.date :release_date
      t.string :cover_image_url
      t.integer :metascore
      t.decimal :user_score, precision: 3, scale: 1
      t.integer :rating_category
      t.references :publisher, null: false, foreign_key: true
      t.references :developer, null: false, foreign_key: true

      t.timestamps
    end
    add_index :games, :slug, unique: true
    add_index :games, :metascore
    add_index :games, :user_score
    add_index :games, :release_date
  end
end
