class AddScoreName < ActiveRecord::Migration
  def change
    add_column :characteristics, :score_name, :string

    Characteristic.find(1).update_attributes(score_name: 'Ripple Effect Score')
    Characteristic.find(7).update_attributes(score_name: 'Performance Score')
  end
end
