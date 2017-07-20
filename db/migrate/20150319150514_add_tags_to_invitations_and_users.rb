class AddTagsToInvitationsAndUsers < ActiveRecord::Migration
  
  def change
    add_column :users, :tags, :string, :array => true, :default => '{}'
    add_column :invitations, :relationship_type, :string
    add_column :invitations, :relationship_tags, :string, :array => true, :default => '{}'
    
    add_index :users, :tags, :using => 'gin'
    add_index :invitations, :relationship_type
    add_index :invitations, :relationship_tags, :using => 'gin'
  end

end
