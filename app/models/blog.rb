class Blog < ActiveRecord::Base
	attr_accessor :image_file_name
	attr_accessor :image_content_type
	has_attached_file :image, :url => "/public/uploads/blogs/:id/blog.jpg",
    :path => ":rails_root/public/uploads/blogs/:id/blog.jpg",
		:default_url => "/uploads/blogs/:id/blog.jpg"
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/
end
