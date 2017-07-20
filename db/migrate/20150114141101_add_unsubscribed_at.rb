class AddUnsubscribedAt < ActiveRecord::Migration
  def change
    add_column :users, :unsubscribed_at, :datetime
    add_column :invitations, :hold_until, :datetime, null: false, default: Time.new(1970)
  end
end
