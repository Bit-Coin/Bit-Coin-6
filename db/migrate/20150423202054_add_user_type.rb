class AddUserType < ActiveRecord::Migration
  def change
    add_column :users, :type, :string, null: false, default: 'prospect'
    change_column :users, :state, :string, null: false, default: 'active'
  end
end
