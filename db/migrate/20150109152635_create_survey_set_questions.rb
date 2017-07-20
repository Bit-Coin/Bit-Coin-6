class CreateSurveySetQuestions < ActiveRecord::Migration
  def change
    create_table :survey_set_questions do |t|
      t.integer :question_id
      t.integer :survey_set_id
      t.integer :position

      t.timestamps
    end
  end
end
