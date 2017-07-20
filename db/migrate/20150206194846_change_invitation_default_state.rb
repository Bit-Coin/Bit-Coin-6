class ChangeInvitationDefaultState < ActiveRecord::Migration
  def change
    change_column_default :invitations, :state, 'pending'
    change_column_default :surveys, :state, 'pending'
    change_column_default :users, :state, 'pending'
  end
end
