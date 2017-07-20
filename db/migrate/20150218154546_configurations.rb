class Configurations < ActiveRecord::Migration
  def change
    create_table :configurations do |t|
      t.timestamps

      t.integer :configurable_id, null: false
      t.string :configurable_type, null: false
      t.string :key, null: false
      t.string :value, null: false
    end
    add_index :configurations, [:configurable_id, :configurable_type]
    add_index :configurations, [:key, :value]

    add_column :questions, :self_phrased, :string
    rename_column :questions, :text, :other_phrased
  end
end
