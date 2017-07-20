# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
%w( dashboards surveys pages users/sessions devise/sessions users/registrations 
    devise/confirmations devise/passwords short_paths 
    invitations).each do |controller|
  Rails.application.config.assets.precompile += ["#{controller}.js", "#{controller}.css"]
end
Rails.application.config.assets.precompile += %w( admin.css )

Rails.application.config.assets.precompile += %w(.svg .eot .woff .ttf)

Rails.application.config.assets.precompile += %w( highcharts-custom.js )

# add all CCL assets in vendor/assets/content to the precompilation list so that they
#  can be served out of production - Goal is to replace this with AWS file cache
Dir.foreach('vendor/assets/content') do |item|
  next if File.directory? item
  Rails.application.config.assets.precompile += ["#{item}"]
end

