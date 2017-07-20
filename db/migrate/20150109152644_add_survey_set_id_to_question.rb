class AddSurveySetIdToQuestion < ActiveRecord::Migration
  def change
    add_column :surveys, :survey_set_id, :integer
    add_index :surveys, :survey_set_id
  end
end
