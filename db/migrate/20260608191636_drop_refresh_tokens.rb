class DropRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    drop_table :refresh_tokens do |t|
      t.bigint   :user_id,    null: false
      t.string   :token,      null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.timestamps
    end
  end
end
