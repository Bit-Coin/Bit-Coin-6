class AddComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.timestamps

      t.string :state, null: false, default: 'draft'
      t.integer :receiver_id, null: false # so user has_many :comments
      t.integer :response_id # belongs_to :question, through: :response 
      t.integer :survey_id, null: false # general comments associate with survey
      t.string :text, null: false
    end
    add_index :comments, :receiver_id
    add_index :comments, :response_id
    add_index :comments, :survey_id
    add_index :comments, :state
  end
end
