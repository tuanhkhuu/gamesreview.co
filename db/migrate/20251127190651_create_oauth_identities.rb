class CreateOauthIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_identities do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.jsonb :raw_info, default: {}

      t.timestamps
    end

    # Composite unique index on provider + uid
    add_index :oauth_identities, [ :provider, :uid ], unique: true

    # Index on provider for filtering
    add_index :oauth_identities, :provider
  end
end
