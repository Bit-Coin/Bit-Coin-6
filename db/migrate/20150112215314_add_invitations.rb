class AddInvitations < ActiveRecord::Migration
  def up
    create_table :invitations do |t|
      t.timestamps
      t.integer :giver_id, null: false
      t.integer :receiver_id, null: false
      t.string :state, null: false, default: 'active'
    end
    add_index :invitations, :giver_id
    add_index :invitations, :receiver_id
  end

  def down
    remove_table :invitations
  end
end
