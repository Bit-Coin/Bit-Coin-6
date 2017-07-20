class CreateSubscriptions < ActiveRecord::Migration
  def change
    
    create_table :plans do |t|
      t.string :name
      t.decimal :price
      t.boolean :stripe_plan, :default => false, :null => false 
      t.string :stripe_id
      t.string :interval
    end
    
    create_table :subscriptions do |t|
      t.integer :team_id
      t.integer :plan_id
      t.integer :owner_id
      t.string :state
      t.string :stripe_token
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.datetime :start_at
      t.datetime :end_at
      t.timestamps
    end
    
    add_index :subscriptions, :team_id
    add_index :subscriptions, :plan_id
    add_index :subscriptions, :owner_id
    
    create_table :subscription_users do |t|
      t.integer :subscription_id
      t.integer :user_id
      t.datetime :start_at
      t.datetime :end_at
      t.timestamps
    end
    
    add_index :subscription_users, :subscription_id
    add_index :subscription_users, :user_id
    
    create_table :subscription_events do |t|
      t.integer :subscription_id
      t.string :event_name
      t.json :body
      t.timestamps
    end
    
    add_index :subscription_events, :subscription_id
  end
end
