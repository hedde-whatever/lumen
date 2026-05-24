class CreateMedia < ActiveRecord::Migration[8.1]
  def change
    create_table :media do |t|
      t.references :user,  null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.string     :path,  null: false

      t.timestamps
    end
  end
end
