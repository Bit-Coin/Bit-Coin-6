class AddProxyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :proxy_id, :integer
    add_column :users, :proxy_secret, :string
    
    add_index :users, :proxy_id
  end
end
