class CreateSurveySets < ActiveRecord::Migration
  def change
    create_table :survey_sets do |t|
      t.string :name
      t.integer :position
      t.boolean :self_survey, :null => false, :default => false
      t.string :state

      t.timestamps
    end
  end
end
