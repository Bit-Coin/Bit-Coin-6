json.array!(@blogs) do |blog|
  json.extract! blog, :id, :title, :description, :author, :image, :published_at, :state
  json.url blog_url(blog, format: :json)
end
