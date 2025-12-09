class CreateDevelopers < ActiveRecord::Migration[8.1]
  def change
    create_table :developers do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :website_url
      t.string :country
      t.text :description

      t.timestamps
    end
    add_index :developers, :slug, unique: true
    add_index :developers, :name, unique: true
  end
end
