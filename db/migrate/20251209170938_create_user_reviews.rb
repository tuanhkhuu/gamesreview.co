class CreateUserReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :user_reviews do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.decimal :score, precision: 3, scale: 1, null: false
      t.integer :completion_status
      t.integer :hours_played
      t.integer :difficulty_rating
      t.integer :moderation_status, default: 0, null: false
      t.text :moderation_reason
      t.datetime :moderated_at
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.references :platform, foreign_key: true

      t.timestamps
    end
    add_index :user_reviews, [ :user_id, :game_id, :platform_id ], unique: true, name: "index_user_reviews_on_user_game_platform"
    add_index :user_reviews, :moderation_status
    add_index :user_reviews, :score
    add_index :user_reviews, :created_at
  end
end
