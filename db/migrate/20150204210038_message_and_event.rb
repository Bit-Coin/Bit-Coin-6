class MessageAndEvent < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.timestamps

      t.integer :messageable_id
      t.string :messageable_type
      t.string :to
      t.string :uuid
      t.string :sender # e.g. SurveysMailer#new_invitation
      t.json :original
    end
    add_index :messages, :uuid
    add_index :messages, [:messageable_id, :messageable_type]

    create_table :events do |t|
      t.timestamps

      t.integer :eventable_id
      t.string :eventable_type
      t.string :type
      t.string :note
      t.json :detail
    end
    add_index :events, [:eventable_id, :eventable_type]
  end
end
