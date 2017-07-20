class ChangeColumnGiveOnly < ActiveRecord::Migration
  def change
    rename_column :users, :give_feedback, :feedback_type
    change_column :users, :feedback_type, :string
  end
end
