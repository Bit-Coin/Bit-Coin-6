class CommentQuestionId < ActiveRecord::Migration
  def change
    add_column :comments, :question_id, :integer
    add_index :comments, :question_id
    execute "update comments set question_id = 
      (select question_id from responses where comments.response_id = responses.id)"
  end
end
