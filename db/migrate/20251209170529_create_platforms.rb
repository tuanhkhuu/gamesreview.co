class CreatePlatforms < ActiveRecord::Migration[8.1]
  def change
    create_table :platforms do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :short_name
      t.integer :platform_type, null: false
      t.string :manufacturer
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :platforms, :slug, unique: true
    add_index :platforms, :name, unique: true
  end
end
