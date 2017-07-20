class AddColumnGiveFeedbackToUser < ActiveRecord::Migration
  def change
    add_column :users, :give_feedback, :boolean
  end
end
