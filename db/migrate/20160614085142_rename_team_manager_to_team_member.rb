class RenameTeamManagerToTeamMember < ActiveRecord::Migration
  def change
  	rename_table :team_managers, :team_members
  end
end
