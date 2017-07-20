class CreateBlogs < ActiveRecord::Migration
  def change
    create_table :blogs do |t|
      t.string :title
      t.text :description
      t.string :author
      t.string :image
      t.datetime :published_at
      t.string :state, default: 'active'

      t.timestamps null: false
    end
  end
end
