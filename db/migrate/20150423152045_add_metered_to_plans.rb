class AddMeteredToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :metered, :boolean, :default => false, :null => false
    add_column :plans, :description, :string
  end
end
