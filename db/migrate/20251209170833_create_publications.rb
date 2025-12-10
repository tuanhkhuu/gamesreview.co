class CreatePublications < ActiveRecord::Migration[8.1]
  def change
    create_table :publications do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :website_url
      t.string :logo_url
      t.decimal :credibility_weight, precision: 3, scale: 1, default: 5.0

      t.timestamps
    end
    add_index :publications, :slug, unique: true
    add_index :publications, :name, unique: true
  end
end
