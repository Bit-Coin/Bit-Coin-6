class AddAccessDevelopmentToolsToUSer < ActiveRecord::Migration
  def change
    add_column :users, :access_development_tools, :boolean, default: false
  end
end
