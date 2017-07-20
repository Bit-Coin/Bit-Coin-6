class AddDevToolsInfoToUser < ActiveRecord::Migration
  def change
    add_column :users, :development_tools_info, :hstore, default: {curious: 0, conscientious: 0, committed: 0, cooperative: 0, consistent: 0, management: 0, executive: 0}
  end
end
