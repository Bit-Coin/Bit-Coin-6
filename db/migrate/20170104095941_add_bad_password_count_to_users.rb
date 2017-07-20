class AddBadPasswordCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :bad_password_count, :integer, null: false, default: 0
    add_column :users, :reset_password_count, :integer, null: false, default: 0
  end
end
