class AddStubToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :stub, :string
    add_index :companies, :stub
    
    remove_index :users, :email
    add_index :users, [:email, :company_id], :unique => true
  end
end
