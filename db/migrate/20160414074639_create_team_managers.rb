class CreateTeamManagers < ActiveRecord::Migration
  def change
    create_table :team_managers do |t|
      t.integer :team_id
      t.integer :manager_id

      t.timestamps null: false
    end
  end
end
