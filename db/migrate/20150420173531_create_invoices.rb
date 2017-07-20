class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.integer :company_id
      t.integer :subscription_id
      t.string :stripe_invoice_id
      t.json :body
      t.timestamps
    end
    
    add_index :invoices, :company_id
    add_index :invoices, :stripe_invoice_id
  end
end
