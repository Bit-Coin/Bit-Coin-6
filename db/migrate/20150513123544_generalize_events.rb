# Run migrate_events.rb after this

class GeneralizeEvents < ActiveRecord::Migration
  def change

    # Fix up the events table
    rename_column :events, :type, :type_old
    add_column :events, :type, :string, null: false, default: ''
    add_index :events, :type
    add_column :events, :company_id, :integer # nil company means "System Event"
    add_index :events, :company_id
    add_column :events, :user_id, :integer
    add_index :events, :user_id
    add_column :events, :severity, :string, null: false, default: 'info'
    add_column :events, :name, :string, null: false, default: ''
    add_index :events, :name
    add_column :events, :body, :jsonb, null: false, default: '{}'
    execute "CREATE INDEX event_body_sg_id ON events USING GIN ((body->'sg_event_id'))"

    # Remove these columns in a migration after migrate_events.rb has run
    rename_column :events, :sg_event_id, :delete_sg_event_id
    rename_column :events, :detail, :delete_detail
    rename_column :events, :type_old, :delete_type_old

    # Get rid of subscription_events table
    puts 'Migrating subscription_events'
    sql = 'select * from subscription_events'
    # can't use SubcriptionEvent here b/c now it inherits from Event
    ActiveRecord::Base.connection.execute(sql).each do |se|
      sub = Subscription.find(se['subscription_id'])
      Event.create!({
        company_id: sub.company.id,
        created_at: DateTime.parse(se['created_at']),
        type: 'SubscriptionEvent',
        eventable: sub,
        name: se['name'],
        body: se['body']
      })
      print '.'
    end
    drop_table :subscription_events
    puts 'dropped'

  end
end
