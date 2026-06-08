class RemovePathFromMedia < ActiveRecord::Migration[8.1]
  def change
    remove_column :media, :path, :string
  end
end
