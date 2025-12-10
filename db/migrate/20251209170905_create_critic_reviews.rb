class CreateCriticReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :critic_reviews do |t|
      t.integer :score, null: false
      t.text :excerpt
      t.string :review_url
      t.string :author_name
      t.datetime :published_at
      t.references :game, null: false, foreign_key: true
      t.references :publication, null: false, foreign_key: true
      t.references :platform, foreign_key: true

      t.timestamps
    end
    add_index :critic_reviews, [ :game_id, :publication_id, :platform_id ], unique: true, name: "index_critic_reviews_on_game_publication_platform"
    add_index :critic_reviews, :score
    add_index :critic_reviews, :published_at
  end
end
