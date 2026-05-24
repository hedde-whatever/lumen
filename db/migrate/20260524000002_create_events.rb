class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :user, null: false, foreign_key: true

      t.string  :name,         null: false
      t.date    :date
      t.string  :country_name
      t.string  :country_code, limit: 2
      t.string  :region_name
      t.string  :city
      t.string  :full_address
      t.string  :address
      t.string  :feature_type
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.text    :note

      t.timestamps
    end

    add_index :events, [ :user_id, :date ]
  end
end
