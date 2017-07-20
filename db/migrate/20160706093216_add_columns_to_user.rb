class AddColumnsToUser < ActiveRecord::Migration
  def change
    add_column :users, :start_date, :date
    add_column :users, :department, :string
    add_column :users, :sex, :string
    add_column :users, :age, :integer
  end
end
