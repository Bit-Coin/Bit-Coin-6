class DropSelfSurvey < ActiveRecord::Migration
  def change
    remove_column :survey_sets, :self_survey 
  end
end
