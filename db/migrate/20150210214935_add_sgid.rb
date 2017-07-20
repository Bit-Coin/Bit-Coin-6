class AddSgid < ActiveRecord::Migration
  def change
    add_column :messages, :sg_message_id, :string
    add_column :events, :sg_event_id, :string
    add_index :messages, :sg_message_id
  end
end
