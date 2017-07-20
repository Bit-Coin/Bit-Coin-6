class FixRippler < ActiveRecord::Migration
  def change
    execute "update invitations set last_notified_on = updated_at where last_notified_on is null"
    change_column_null :invitations, :last_notified_on, false
    rename_column :invitations, :last_notified_on, :reminded_at
    change_column_null :invitations, :hold_until, false
    add_index :invitations, :reminded_at

    execute "update users set state = 'rippler' where state is null"
    change_column_null :users, :state, false, 'pending'
  end
end
