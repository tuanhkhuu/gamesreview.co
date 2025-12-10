# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_09_171043) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "critic_reviews", force: :cascade do |t|
    t.string "author_name"
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.bigint "game_id", null: false
    t.bigint "platform_id"
    t.bigint "publication_id", null: false
    t.datetime "published_at"
    t.string "review_url"
    t.integer "score", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "publication_id", "platform_id"], name: "index_critic_reviews_on_game_publication_platform", unique: true
    t.index ["game_id"], name: "index_critic_reviews_on_game_id"
    t.index ["platform_id"], name: "index_critic_reviews_on_platform_id"
    t.index ["publication_id"], name: "index_critic_reviews_on_publication_id"
    t.index ["published_at"], name: "index_critic_reviews_on_published_at"
    t.index ["score"], name: "index_critic_reviews_on_score"
  end

  create_table "developers", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["name"], name: "index_developers_on_name", unique: true
    t.index ["slug"], name: "index_developers_on_slug", unique: true
  end

  create_table "game_genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.bigint "genre_id", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "genre_id"], name: "index_game_genres_on_game_id_and_genre_id", unique: true
    t.index ["game_id"], name: "index_game_genres_on_game_id"
    t.index ["genre_id"], name: "index_game_genres_on_genre_id"
  end

  create_table "game_platforms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.bigint "platform_id", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "platform_id"], name: "index_game_platforms_on_game_id_and_platform_id", unique: true
    t.index ["game_id"], name: "index_game_platforms_on_game_id"
    t.index ["platform_id"], name: "index_game_platforms_on_platform_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "developer_id", null: false
    t.integer "metascore"
    t.bigint "publisher_id", null: false
    t.integer "rating_category"
    t.date "release_date"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.decimal "user_score"
    t.index ["developer_id"], name: "index_games_on_developer_id"
    t.index ["metascore"], name: "index_games_on_metascore"
    t.index ["publisher_id"], name: "index_games_on_publisher_id"
    t.index ["release_date"], name: "index_games_on_release_date"
    t.index ["slug"], name: "index_games_on_slug", unique: true
    t.index ["user_score"], name: "index_games_on_user_score"
  end

  create_table "genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_genres_on_name", unique: true
    t.index ["slug"], name: "index_genres_on_slug", unique: true
  end

  create_table "oauth_identities", force: :cascade do |t|
    t.text "access_token"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "provider", null: false
    t.jsonb "raw_info", default: {}
    t.text "refresh_token"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_oauth_identities_on_provider_and_uid", unique: true
    t.index ["provider"], name: "index_oauth_identities_on_provider"
    t.index ["user_id"], name: "index_oauth_identities_on_user_id"
  end

  create_table "platforms", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "manufacturer"
    t.string "name", null: false
    t.integer "platform_type", null: false
    t.string "short_name"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_platforms_on_name", unique: true
    t.index ["slug"], name: "index_platforms_on_slug", unique: true
  end

  create_table "publications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "credibility_weight", precision: 3, scale: 1, default: "5.0"
    t.string "logo_url"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["name"], name: "index_publications_on_name", unique: true
    t.index ["slug"], name: "index_publications_on_slug", unique: true
  end

  create_table "publishers", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["name"], name: "index_publishers_on_name", unique: true
    t.index ["slug"], name: "index_publishers_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_reviews", force: :cascade do |t|
    t.text "body", null: false
    t.integer "completion_status"
    t.datetime "created_at", null: false
    t.integer "difficulty_rating"
    t.bigint "game_id", null: false
    t.integer "hours_played"
    t.datetime "moderated_at"
    t.text "moderation_reason"
    t.integer "moderation_status", default: 0, null: false
    t.bigint "platform_id"
    t.decimal "score", precision: 3, scale: 1, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_user_reviews_on_created_at"
    t.index ["game_id"], name: "index_user_reviews_on_game_id"
    t.index ["moderation_status"], name: "index_user_reviews_on_moderation_status"
    t.index ["platform_id"], name: "index_user_reviews_on_platform_id"
    t.index ["score"], name: "index_user_reviews_on_score"
    t.index ["user_id", "game_id", "platform_id"], name: "index_user_reviews_on_user_game_platform", unique: true
    t.index ["user_id"], name: "index_user_reviews_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.boolean "email_verified", default: false, null: false
    t.string "name"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_verified"], name: "index_users_on_email_verified"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "critic_reviews", "games"
  add_foreign_key "critic_reviews", "platforms"
  add_foreign_key "critic_reviews", "publications"
  add_foreign_key "game_genres", "games"
  add_foreign_key "game_genres", "genres"
  add_foreign_key "game_platforms", "games"
  add_foreign_key "game_platforms", "platforms"
  add_foreign_key "games", "developers"
  add_foreign_key "games", "publishers"
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_reviews", "games"
  add_foreign_key "user_reviews", "platforms"
  add_foreign_key "user_reviews", "users"
end
