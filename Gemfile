source 'https://rubygems.org'
source 'https://rails-assets.org'

ruby '2.1.4'

gem 'rails', '5.0.0'
gem 'dotenv-rails', groups: [ :development, :test ]  # load this before anything else

# Data
gem 'acts-as-taggable-array-on'
gem 'attr_encrypted'
gem 'aws-sdk'
gem 'descriptive_statistics', '~> 2.4.0', :require => 'descriptive_statistics/safe'
gem 'faker'
gem 'pg'
gem 'phony_rails'

# Assets
gem 'coffee-rails', '~> 4.1.1'
gem 'nokogiri'
gem 'sass-rails', '~> 5.0.5'
gem 'slim'
gem 'therubyracer',  platforms: :ruby
gem 'uglifier', '>= 1.3.0'

# Auth
gem 'devise', '>= 4.0.0'
gem 'simple_token_authentication', '~> 1.14', '>= 1.14.0'

# Front-end
gem 'autoprefixer-rails'
gem 'bootstrap_form'
gem 'draper', '>= 2.1.0'
gem 'font-awesome-rails', '>= 4.5.0.1'
gem 'jbuilder'
gem 'modernizr-rails'
gem 'useragent'

# Back-end
gem 'aasm'
gem 'business_time'
gem 'kaminari', '>= 0.16.3'
gem 'paperclip', require: 'paperclip'
gem 'rails_admin', '>= 1.0.0'
gem 'resque', '>= 1.25.2'
gem 'resque_mailer', '>= 2.2.7'
gem 'resque-scheduler', '>= 4.0.0'
gem 'stripe'
gem 'impressionist'

# Services
gem 'sendgrid-ruby' # sending
gem 'sendgrid_toolkit', '>= 1.1.1' # api functions (bounces, etc.)
gem 'twilio-ruby', '~> 3.12'
gem "select2-rails"
gem 'readmorejs-rails', '>= 0.0.12'

group :test do
  gem 'capybara-screenshot', '>= 1.0.9'
  gem 'database_cleaner'
  gem 'minitest'
  gem 'minitest-rails-capybara', '~> 3.0.0'
  gem 'minitest-reporters'
  gem 'poltergeist', '~> 1.6.0'
  gem 'resque_unit'
  gem 'timecop'
  gem 'webmock'
end

group :development, :test do
  gem 'mailcatcher', '>= 0.6.1'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rubocop', '~> 0.46.0', require: false
  gem 'bullet'
end

group :production, :staging do
  gem 'rails_12factor'
  gem 'rails_stdout_logging'
end

group :production do
  gem 'honeybadger', '~> 2.0'
  gem 'newrelic_rpm'
end

group :staging, :test, :production do
  gem 'unicorn', '>= 4.9.0'
  gem 'unicorn-rails', '>= 2.2.0'
end
gem 'ckeditor_rails', '>= 4.5.10'
