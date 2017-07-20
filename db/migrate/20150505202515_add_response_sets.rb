class AddResponseSets < ActiveRecord::Migration
  def change
    create_table :response_sets do |t|
      t.timestamps
      t.string :description, null: false
      t.hstore :values, default: {}, null: false
    end

    add_column :questions, :response_set_id, :integer, null: false, default: 1
    add_index :questions, :response_set_id
  end
end

# Run db/script/one_time/migrate_response_sets.rb after this
