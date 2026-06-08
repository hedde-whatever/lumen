class DropProviderIdentities < ActiveRecord::Migration[8.1]
  def change
    drop_table :provider_identities, if_exists: true do |t|
      t.bigint :user_id,  null: false
      t.string :provider, null: false
      t.string :uid,      null: false
      t.timestamps
    end
  end
end
