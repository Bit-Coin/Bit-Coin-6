class CleanUpCompany < ActiveRecord::Migration
  class TempTeam < ActiveRecord::Base; end  
  
  def change
    create_table :temp_teams do |t|
      t.timestamps
      t.string :name
      t.integer :company_id
      t.integer :manager_id
    end

    Team.where('parent_team_id is not null').each do |old|
      raise "Cannot move deeply nested Team #{old.id}" unless Team.find(old.parent_team_id).parent_team_id.blank?
      gnu = TempTeam.create!({
        name: old.name,
        company_id: old.parent_team_id,
        manager_id: old.manager_id
      })
      User.where('team_id = ?', old.id).update_all(team_id: gnu.id)
      Configuration.where('configurable_type = ? and configurable_id = ?', 'Team', old.id)
        .update_all(configurable_id: gnu.id)
      old.destroy
    end

    rename_table :teams, :companies
    remove_column :companies, :parent_team_id
    drop_table :team_hierarchies
    rename_table :temp_teams, :teams
    add_index :teams, :company_id
    rename_column :subscriptions, :team_id, :company_id
  end
end
