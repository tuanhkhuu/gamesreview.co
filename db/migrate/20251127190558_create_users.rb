class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, index: { unique: true }
      # Removed password_digest - OAuth only authentication

      t.string :name
      t.string :avatar_url
      t.boolean :email_verified, null: false, default: false

      t.timestamps
    end

    # Optional: Add index on email_verified if filtering by verification status
    add_index :users, :email_verified
  end
end
