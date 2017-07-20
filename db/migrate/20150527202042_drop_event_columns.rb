class DropEventColumns < ActiveRecord::Migration
  def change
    remove_column :events, :delete_detail
    remove_column :events, :delete_type_old
    remove_column :events, :delete_sg_event_id
  end
end
