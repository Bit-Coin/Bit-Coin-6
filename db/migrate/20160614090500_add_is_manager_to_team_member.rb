class AddIsManagerToTeamMember < ActiveRecord::Migration
  def change
    add_column :team_members, :is_manager, :boolean, default: false
		rename_column :team_members, :manager_id, :user_id
  end
end
