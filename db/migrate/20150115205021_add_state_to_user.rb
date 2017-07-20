class AddStateToUser < ActiveRecord::Migration
  def change
    add_column :users, :state, :string
    add_index :users, :state
  end
end
