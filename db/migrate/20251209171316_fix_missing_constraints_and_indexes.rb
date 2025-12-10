class FixMissingConstraintsAndIndexes < ActiveRecord::Migration[8.1]
  def change
    # Add missing null constraints
    change_column_null :games, :title, false
    change_column_null :games, :slug, false
    change_column_null :genres, :name, false
    change_column_null :genres, :slug, false
    change_column_null :platforms, :name, false
    change_column_null :platforms, :slug, false
    change_column_null :platforms, :platform_type, false
    change_column_null :platforms, :active, false
    change_column_null :publishers, :name, false
    change_column_null :publishers, :slug, false

    # Set default for platforms.active
    change_column_default :platforms, :active, true

    # Add missing unique indexes
    add_index :genres, :name, unique: true
    add_index :platforms, :name, unique: true
    add_index :publishers, :name, unique: true

    # Add missing performance indexes for games
    add_index :games, :metascore
    add_index :games, :user_score
    add_index :games, :release_date

    # Add missing composite index for game_platforms
    add_index :game_platforms, [ :game_id, :platform_id ], unique: true
  end
end
