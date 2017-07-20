class AddTeamType < ActiveRecord::Migration
  def change
    add_column :teams, :type, :string, null: false, default: 'pilot'
    add_index :teams, :type

    # Set these by hand
    # [#<Company id: 1, name: "Acme Demo, Inc.">, #<Company id: 5, 
    #  name: "Ripple Analytics Inc.">, #<Company id: 9, 
    #  name: "Angel's Ripplecrew">, #<Company id: 10, 
    #  name: "athenahealth, Inc.">, #<Company id: 11, 
    #  name: "PatientsLikeMe">, #<Company id: 15, name: "UNFCU">]>
  end
end
