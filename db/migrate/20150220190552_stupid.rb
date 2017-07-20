class Stupid < ActiveRecord::Migration
  def change
    add_column :survey_sets, :self_survey, :boolean, null: false, default: false
  end
end
