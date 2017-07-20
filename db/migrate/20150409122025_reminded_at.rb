class RemindedAt < ActiveRecord::Migration
  def change
    # Once this migration is run, all users with open surveys will be reminded
    # at the next 8:34am run (unless overridden by custom settings).
    add_column :users, :last_reminded_at, :datetime, null: false, default: '1970-01-01 00:00:00 America/New_York'
    add_index :users, :last_reminded_at
  end
end
