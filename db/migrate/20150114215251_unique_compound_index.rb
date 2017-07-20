class UniqueCompoundIndex < ActiveRecord::Migration
  def change
    add_index :invitations, [:giver_id, :receiver_id], unique: true
  end
end
