class AddLastNotified < ActiveRecord::Migration
  def change
    add_column :invitations, :last_notified_on, :datetime
  end
end
