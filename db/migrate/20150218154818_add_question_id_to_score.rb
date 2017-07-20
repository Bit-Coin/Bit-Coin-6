class AddQuestionIdToScore < ActiveRecord::Migration
  def change
    add_column :scores, :question_id, :integer
    
    add_index :scores, :question_id
  end
end
